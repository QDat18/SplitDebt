package com.splitdebt.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.splitdebt.api.config.LegalProperties;
import com.splitdebt.api.dto.RegisterRequest;
import com.splitdebt.api.dto.consent.RegisterConsentsDto;
import com.splitdebt.api.repository.GroupMessageRepository;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.FcmPushService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.emptyOrNullString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class GroupChatNoTxTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private UserRepository userRepository;
    @Autowired private GroupMessageRepository groupMessageRepository;
    @Autowired private LegalProperties legalProperties;

    @MockBean private FcmPushService push;

    private record TestUser(Long id, String email, String fullName, String token) {}

    private TestUser register(String prefix) throws Exception {
        String email = prefix + "_" + System.nanoTime() + "@test.com";
        String fullName = "User " + prefix;
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
        String token = objectMapper.readTree(res.getResponse().getContentAsString())
                .path("data").path("token").asText();
        Long id = userRepository.findByEmail(email).orElseThrow().getId();
        return new TestUser(id, email, fullName, token);
    }

    private long createGroup(String token, String name) throws Exception {
        MvcResult res = mockMvc.perform(post("/api/groups")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("name", name))))
                .andExpect(status().isCreated())
                .andReturn();
        return objectMapper.readTree(res.getResponse().getContentAsString())
                .path("data").path("id").asLong();
    }

    private void cleanupGroup(String token, long groupId) throws Exception {
        groupMessageRepository.deleteByGroupId(groupId);
        mockMvc.perform(delete("/api/groups/" + groupId)
                        .header("Authorization", "Bearer " + token));
    }

    @Test
    void resendSameClientMessageId_returns200WithSameId() throws Exception {
        TestUser u = register("resend");
        long groupId = createGroup(u.token(), "NoTx Resend Group");
        try {
            String clientMsgId = UUID.randomUUID().toString();
            String body = objectMapper.writeValueAsString(Map.of(
                    "content", "Hello idempotency",
                    "clientMessageId", clientMsgId
            ));

            MvcResult first = mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                            .header("Authorization", "Bearer " + u.token())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(body))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.data.senderName").value(u.fullName()))
                    .andReturn();

            long msgId = objectMapper.readTree(first.getResponse().getContentAsString())
                    .path("data").path("id").asLong();

            mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                            .header("Authorization", "Bearer " + u.token())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(body))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.id").value(msgId))
                    .andExpect(jsonPath("$.data.senderName").value(u.fullName()));
        } finally {
            cleanupGroup(u.token(), groupId);
        }
    }

    @Test
    void firstSend_returnsSenderName() throws Exception {
        TestUser u = register("firstsend");
        long groupId = createGroup(u.token(), "NoTx FirstSend Group");
        try {
            String body = objectMapper.writeValueAsString(Map.of(
                    "content", "First message",
                    "clientMessageId", UUID.randomUUID().toString()
            ));

            mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                            .header("Authorization", "Bearer " + u.token())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(body))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.data.senderName", not(emptyOrNullString())))
                    .andExpect(jsonPath("$.data.senderName").value(u.fullName()));
        } finally {
            cleanupGroup(u.token(), groupId);
        }
    }
}

