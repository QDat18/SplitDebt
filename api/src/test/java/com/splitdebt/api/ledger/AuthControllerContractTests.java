package com.splitdebt.api.ledger;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class AuthControllerContractTests {
    @Autowired MockMvc mvc;

    private String email() {
        return "auth." + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
    }

    @Test
    void registrationLoginAndProtectedRouteContract() throws Exception {
        String email = email();
        mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Alice Example","email":"%s","phone":"0900000000","password":"password123","acceptedTerms":true}
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", greaterThan(0)))
                .andExpect(jsonPath("$.message", not(emptyString())))
                .andExpect(jsonPath("$.token", not(emptyString())))
                .andExpect(jsonPath("$.user.email").value(email))
                .andExpect(jsonPath("$.passwordHash").doesNotExist());

        String login = mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"password123"}
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token", not(emptyString())))
                .andExpect(jsonPath("$.user.email").value(email))
                .andReturn().getResponse().getContentAsString();

        String token = new com.fasterxml.jackson.databind.ObjectMapper().readTree(login).get("token").asText();
        mvc.perform(get("/api/groups").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
        mvc.perform(get("/api/groups"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message", not(emptyString())));
    }

    @Test
    void duplicateEmailReturnsConflict() throws Exception {
        String email = email();
        String payload = """
                {"fullName":"Duplicate User","email":"%s","password":"password123","acceptedTerms":true}
                """.formatted(email);
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content(payload))
                .andExpect(status().isOk());
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content(payload))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message", containsString("Email")));
    }

    @Test
    void registrationValidationRejectsBadInputAndMissingTerms() throws Exception {
        mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"A","email":"not-an-email","password":"123","acceptedTerms":true}
                                """))
                .andExpect(status().isBadRequest());

        mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Valid Name","email":"%s","password":"password123","acceptedTerms":false}
                                """.formatted(email())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("Terms")));
    }

    @Test
    void wrongPasswordAndMalformedOrTamperedTokensAreRejected() throws Exception {
        String email = email();
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content("""
                {"fullName":"Login User","email":"%s","password":"password123","acceptedTerms":true}
                """.formatted(email))).andExpect(status().isOk());

        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content("""
                {"email":"%s","password":"wrong-password"}
                """.formatted(email)))
                .andExpect(status().isUnauthorized());

        mvc.perform(get("/api/overview").header("Authorization", "Bearer not-a-token"))
                .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/overview").header("Authorization", "Token abc"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void malformedJsonGetsFriendlyBadRequestInsteadOfServerError() throws Exception {
        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{broken"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", not(emptyString())));
    }
    @Test
    void forgotPasswordCodeCanResetPasswordWithoutRevealingTheHash() throws Exception {
        String email = email();
        mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Reset User","email":"%s","password":"old-password-123","acceptedTerms":true}
                                """.formatted(email)))
                .andExpect(status().isOk());

        String forgot = mvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"%s\"}".formatted(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", not(emptyString())))
                .andExpect(jsonPath("$.devCode", matchesPattern("\\d{6}")))
                .andReturn().getResponse().getContentAsString();

        String code = new com.fasterxml.jackson.databind.ObjectMapper()
                .readTree(forgot).get("devCode").asText();
        mvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","code":"%s","newPassword":"new-password-456"}
                                """.formatted(email, code)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", not(emptyString())));

        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content("""
                {"email":"%s","password":"old-password-123"}
                """.formatted(email)))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content("""
                {"email":"%s","password":"new-password-456"}
                """.formatted(email)))
                .andExpect(status().isOk());
    }

    @Test
    void googleAuthEndpointIsPublicAndReportsMissingConfigurationCleanly() throws Exception {
        mvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"dummy-token\"}"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.message", containsString("Google")));
    }

}
