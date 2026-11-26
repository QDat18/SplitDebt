/**
 * Trách nhiệm file: Kiểm thử các API đồng ý quyền riêng tư, đăng ký kèm đồng ý và cập nhật đồng ý.
 */

package com.splitdebt.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.splitdebt.api.config.LegalProperties;
import com.splitdebt.api.dto.LoginRequest;
import com.splitdebt.api.dto.RegisterRequest;
import com.splitdebt.api.dto.consent.ConsentItemDto;
import com.splitdebt.api.dto.consent.ConsentUpdateRequest;
import com.splitdebt.api.dto.consent.RegisterConsentsDto;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.UserConsent;
import com.splitdebt.api.entity.enums.ConsentSource;
import com.splitdebt.api.entity.enums.ConsentType;
import com.splitdebt.api.repository.UserConsentRepository;
import com.splitdebt.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;

import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class ConsentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserConsentRepository userConsentRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private LegalProperties legalProperties;

    private RegisterRequest validRegisterRequest(String email) {
        RegisterRequest req = new RegisterRequest();
        req.setFullName("Nguyen Van A");
        req.setEmail(email);
        req.setPassword("Password123!");
        RegisterConsentsDto consents = new RegisterConsentsDto();
        consents.setTermsVersion(legalProperties.getTermsVersion());
        consents.setPrivacyVersion(legalProperties.getPrivacyVersion());
        consents.setAgeConfirmed(true);
        req.setConsents(consents);
        req.setPlatform("android");
        req.setAppVersion("1.0.0");
        return req;
    }

    private String loginAndGetToken(String email, String password) throws Exception {
        LoginRequest login = new LoginRequest();
        login.setEmail(email);
        login.setPassword(password);
        MvcResult res = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(login)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(res.getResponse().getContentAsString())
                .path("data").path("token").asText();
    }

    @Test
    void register_withoutConsents_is400() throws Exception {
        RegisterRequest req = new RegisterRequest();
        req.setFullName("Nguyen Van A");
        req.setEmail("noconsent_" + System.nanoTime() + "@test.com");
        req.setPassword("Password123!");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("Bạn cần đồng ý Điều khoản, Chính sách và xác nhận đủ 16 tuổi để đăng ký.")));
    }

    @Test
    void register_ageNotConfirmed_is400() throws Exception {
        RegisterRequest req = validRegisterRequest("noage_" + System.nanoTime() + "@test.com");
        req.getConsents().setAgeConfirmed(false);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("Bạn cần đồng ý Điều khoản, Chính sách và xác nhận đủ 16 tuổi để đăng ký.")));
    }

    @Test
    void register_staleVersion_is400() throws Exception {
        RegisterRequest req = validRegisterRequest("stale_" + System.nanoTime() + "@test.com");
        req.getConsents().setTermsVersion("2000-01-01");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("Văn bản đã được cập nhật")));
    }

    @Test
    void register_valid_creates3ConsentRecords() throws Exception {
        String email = "valid_" + System.nanoTime() + "@test.com";
        RegisterRequest req = validRegisterRequest(email);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token").exists());

        User user = userRepository.findByEmail(email).orElseThrow();
        List<UserConsent> records = userConsentRepository.findByUserIdOrderByIdAsc(user.getId());
        assertEquals(3, records.size());
        assertTrue(records.stream().allMatch(UserConsent::isGranted));
        assertTrue(records.stream().allMatch(r -> r.getSource() == ConsentSource.REGISTER));
        assertTrue(records.stream().allMatch(r -> "android".equals(r.getPlatform())));
        assertEquals(
                List.of(ConsentType.TERMS, ConsentType.PRIVACY, ConsentType.AGE_16),
                records.stream().map(UserConsent::getConsentType).toList()
        );
    }

    @Test
    void me_returnsConsentBlock() throws Exception {
        String email = "me_" + System.nanoTime() + "@test.com";
        RegisterRequest req = validRegisterRequest(email);

        MvcResult regRes = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();
        String token = objectMapper.readTree(regRes.getResponse().getContentAsString())
                .path("data").path("token").asText();

        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.consent.reconsentRequired").value(false))
                .andExpect(jsonPath("$.consent.acceptedAt").isNotEmpty())
                .andExpect(jsonPath("$.consent.termsVersion").value(legalProperties.getTermsVersion()))
                .andExpect(jsonPath("$.consent.privacyVersion").value(legalProperties.getPrivacyVersion()));
    }

    @Test
    void legacyUserWithoutRecords_requiresReconsent() throws Exception {
        String email = "legacy_" + System.nanoTime() + "@test.com";
        User user = User.builder()
                .fullName("Legacy User")
                .email(email)
                .passwordHash(passwordEncoder.encode("Password123!"))
                .build();
        userRepository.save(user);

        String token = loginAndGetToken(email, "Password123!");
        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.consent.reconsentRequired").value(true))
                .andExpect(jsonPath("$.consent.acceptedAt").doesNotExist());
    }

    @Test
    void withdrawRequiredConsent_is400() throws Exception {
        String email = "withdraw_" + System.nanoTime() + "@test.com";
        MvcResult regRes = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRegisterRequest(email))))
                .andExpect(status().isOk())
                .andReturn();
        String token = objectMapper.readTree(regRes.getResponse().getContentAsString())
                .path("data").path("token").asText();

        ConsentUpdateRequest update = new ConsentUpdateRequest();
        update.setSource(ConsentSource.RECONSENT);
        update.setPlatform("ios");
        update.setAppVersion("1.0.0");
        ConsentItemDto item = new ConsentItemDto();
        item.setType(ConsentType.TERMS);
        item.setGranted(false);
        item.setVersion(legalProperties.getTermsVersion());
        update.setItems(List.of(item));

        mockMvc.perform(post("/api/users/me/consents")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(update)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("Để rút lại đồng ý bắt buộc, hãy xoá tài khoản.")));
    }

    @Test
    void reconsentTwice_appendsRecords() throws Exception {
        String email = "twice_" + System.nanoTime() + "@test.com";
        MvcResult regRes = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRegisterRequest(email))))
                .andExpect(status().isOk())
                .andReturn();
        String token = objectMapper.readTree(regRes.getResponse().getContentAsString())
                .path("data").path("token").asText();
        User user = userRepository.findByEmail(email).orElseThrow();

        String originalTerms = legalProperties.getTermsVersion();
        String originalPrivacy = legalProperties.getPrivacyVersion();
        try {
            legalProperties.setTermsVersion("2026-12-01");
            legalProperties.setPrivacyVersion("2026-12-01");

            ConsentUpdateRequest req1 = new ConsentUpdateRequest();
            req1.setSource(ConsentSource.RECONSENT);
            req1.setPlatform("android");
            req1.setAppVersion("1.0.1");
            req1.setItems(List.of(
                    new ConsentItemDto(ConsentType.TERMS, true, "2026-12-01"),
                    new ConsentItemDto(ConsentType.PRIVACY, true, "2026-12-01")
            ));

            mockMvc.perform(post("/api/users/me/consents")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(req1)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.reconsentRequired").value(false));

            legalProperties.setTermsVersion("2026-12-15");
            legalProperties.setPrivacyVersion("2026-12-15");

            ConsentUpdateRequest req2 = new ConsentUpdateRequest();
            req2.setSource(ConsentSource.RECONSENT);
            req2.setPlatform("ios");
            req2.setAppVersion("1.0.2");
            req2.setItems(List.of(
                    new ConsentItemDto(ConsentType.TERMS, true, "2026-12-15"),
                    new ConsentItemDto(ConsentType.PRIVACY, true, "2026-12-15")
            ));

            mockMvc.perform(post("/api/users/me/consents")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(req2)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.reconsentRequired").value(false));

            List<UserConsent> all = userConsentRepository.findByUserIdOrderByIdAsc(user.getId());
            assertEquals(7, all.size());
            assertEquals(originalTerms, all.get(0).getVersion());
            assertEquals("2026-12-01", all.get(3).getVersion());
            assertEquals("2026-12-15", all.get(5).getVersion());
        } finally {
            legalProperties.setTermsVersion(originalTerms);
            legalProperties.setPrivacyVersion(originalPrivacy);
        }
    }

    @Test
    void reconsent_clearsFlag() throws Exception {
        String email = "clear_" + System.nanoTime() + "@test.com";
        User user = User.builder()
                .fullName("Old User")
                .email(email)
                .passwordHash(passwordEncoder.encode("Password123!"))
                .build();
        userRepository.save(user);
        String token = loginAndGetToken(email, "Password123!");

        ConsentUpdateRequest req = new ConsentUpdateRequest();
        req.setSource(ConsentSource.RECONSENT);
        req.setPlatform("android");
        req.setAppVersion("1.0.0");
        req.setItems(List.of(
                new ConsentItemDto(ConsentType.TERMS, true, legalProperties.getTermsVersion()),
                new ConsentItemDto(ConsentType.PRIVACY, true, legalProperties.getPrivacyVersion())
        ));

        mockMvc.perform(post("/api/users/me/consents")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reconsentRequired").value(false));
    }

    @Test
    void legacyUser_businessApi_is428() throws Exception {
        String email = "block428_" + System.nanoTime() + "@test.com";
        userRepository.save(User.builder()
                .fullName("Legacy 428")
                .email(email)
                .passwordHash(passwordEncoder.encode("Password123!"))
                .build());
        String token = loginAndGetToken(email, "Password123!");

        mockMvc.perform(get("/api/groups")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().is(428))
                .andExpect(jsonPath("$.code").value("RECONSENT_REQUIRED"));
    }

    @Test
    void legacyUser_exemptRoutes_pass() throws Exception {
        String email = "exempt_" + System.nanoTime() + "@test.com";
        userRepository.save(User.builder()
                .fullName("Legacy Exempt")
                .email(email)
                .passwordHash(passwordEncoder.encode("Password123!"))
                .build());
        String token = loginAndGetToken(email, "Password123!");

        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }

    @Test
    void afterReconsent_businessApi_passes() throws Exception {
        String email = "unblock_" + System.nanoTime() + "@test.com";
        userRepository.save(User.builder()
                .fullName("Legacy Unblock")
                .email(email)
                .passwordHash(passwordEncoder.encode("Password123!"))
                .build());
        String token = loginAndGetToken(email, "Password123!");

        mockMvc.perform(get("/api/groups")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().is(428));

        ConsentUpdateRequest req = new ConsentUpdateRequest();
        req.setSource(ConsentSource.RECONSENT);
        req.setPlatform("android");
        req.setAppVersion("1.0.0");
        req.setItems(List.of(
                new ConsentItemDto(ConsentType.TERMS, true, legalProperties.getTermsVersion()),
                new ConsentItemDto(ConsentType.PRIVACY, true, legalProperties.getPrivacyVersion())
        ));
        mockMvc.perform(post("/api/users/me/consents")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/groups")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }

    @Test
    void unauthenticated_isStill401() throws Exception {
        mockMvc.perform(get("/api/groups"))
                .andExpect(status().isUnauthorized());
    }
}

