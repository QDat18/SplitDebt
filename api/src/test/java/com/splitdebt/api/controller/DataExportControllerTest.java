/**
 * Trách nhiệm file: Kiểm thử API xem/xuất dữ liệu cá nhân của người dùng.
 */

package com.splitdebt.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.splitdebt.api.config.LegalProperties;
import com.splitdebt.api.dto.RegisterRequest;
import com.splitdebt.api.dto.consent.RegisterConsentsDto;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.ConsentService;
import com.splitdebt.api.service.FcmPushService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasSize;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class DataExportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ConsentService consentService;

    @Autowired
    private LegalProperties legalProperties;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @MockBean
    private FcmPushService fcmPushService;

    private String registerUser(String email, String fullName) throws Exception {
        RegisterRequest req = new RegisterRequest();
        req.setFullName(fullName);
        req.setEmail(email);
        req.setPassword("Password123!");
        req.setConsents(new RegisterConsentsDto(
                legalProperties.getTermsVersion(),
                legalProperties.getPrivacyVersion(),
                true
        ));
        req.setPlatform("android");
        req.setAppVersion("1.0.0");

        MvcResult res = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(res.getResponse().getContentAsString())
                .path("data").path("token").asText();
    }

    @Test
    void export_containsOwnData() throws Exception {
        String emailA = "exporta_" + System.nanoTime() + "@test.com";
        String tokenA = registerUser(emailA, "User Export A");
        Long userAId = userRepository.findByEmail(emailA).orElseThrow().getId();

        MvcResult groupRes = mockMvc.perform(post("/api/groups")
                        .header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Export Group\"}"))
                .andExpect(status().isCreated())
                .andReturn();
        long groupId = objectMapper.readTree(groupRes.getResponse().getContentAsString())
                .path("data").path("id").asLong();

        var expense = Map.of(
                "groupId", groupId,
                "payerId", userAId,
                "title", "Lunch",
                "totalAmount", 100000,
                "expenseDate", "2026-11-26",
                "splitType", "EQUAL",
                "participants", List.of(Map.of("userId", userAId))
        );
        mockMvc.perform(post("/api/v1/expenses")
                        .header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(expense)))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "content", "Hello export",
                                "clientMessageId", UUID.randomUUID().toString()
                        ))))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/users/me/data-export")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.profile.email").value(emailA))
                .andExpect(jsonPath("$.data.groups", hasSize(1)))
                .andExpect(jsonPath("$.data.expenses.length()", greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.messages.length()", greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.consents.length()", greaterThanOrEqualTo(3)))
                .andExpect(jsonPath("$.data.exportedAt").isNotEmpty());
    }

    @Test
    void export_excludesSecrets() throws Exception {
        String email = "secret_" + System.nanoTime() + "@test.com";
        String token = registerUser(email, "User Secret");

        MvcResult res = mockMvc.perform(get("/api/users/me/data-export")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn();
        String body = res.getResponse().getContentAsString();
        assertFalse(body.contains("passwordHash"));
        assertFalse(body.contains("token"));
    }

    @Test
    void export_excludesOthersMessages() throws Exception {
        String emailA = "msga_" + System.nanoTime() + "@test.com";
        String emailB = "msgb_" + System.nanoTime() + "@test.com";
        String tokenA = registerUser(emailA, "User A");
        String tokenB = registerUser(emailB, "User B");

        MvcResult groupRes = mockMvc.perform(post("/api/groups")
                        .header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Chat Export Group\"}"))
                .andExpect(status().isCreated())
                .andReturn();
        long groupId = objectMapper.readTree(groupRes.getResponse().getContentAsString())
                .path("data").path("id").asLong();

        mockMvc.perform(post("/api/groups/" + groupId + "/members")
                        .header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", emailB))))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", "Bearer " + tokenB)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "content", "PRIVATE_MSG_FROM_B",
                                "clientMessageId", UUID.randomUUID().toString()
                        ))))
                .andExpect(status().isCreated());

        MvcResult res = mockMvc.perform(get("/api/users/me/data-export")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andReturn();
        assertFalse(res.getResponse().getContentAsString().contains("PRIVATE_MSG_FROM_B"));
    }

    @Test
    void export_requiresAuth() throws Exception {
        mockMvc.perform(get("/api/users/me/data-export"))
                .andExpect(status().isUnauthorized());
    }
}

