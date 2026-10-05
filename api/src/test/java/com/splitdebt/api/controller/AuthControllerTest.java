/**
 * Trách nhiệm file: Kiểm thử hành vi của Auth Controller Test, bao gồm các trường hợp thành công và biên quan trọng.
 */

package com.splitdebt.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.splitdebt.api.dto.LoginRequest;
import com.splitdebt.api.dto.RegisterRequest;
import com.splitdebt.api.security.GoogleTokenVerifier;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    /** Cô lập việc gọi máy chủ Google; lớp verifier có kiểm tra riêng ở runtime. */
    @MockBean
    private GoogleTokenVerifier googleTokenVerifier;

    @Test
    void register_success() throws Exception {
        RegisterRequest req = new RegisterRequest();
        req.setFullName("Test User");
        req.setEmail("test" + System.currentTimeMillis() + "@test.com");
        req.setPassword("Password123!");
        
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(200))
                .andExpect(jsonPath("$.data.token").exists());
    }

    @Test
    void register_badRequest() throws Exception {
        RegisterRequest req = new RegisterRequest(); // missing fields
        
        // This might return 400 or 500 depending on how validation is implemented.
        // Usually handled by MethodArgumentNotValidException or DB ConstraintViolation
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400));
    }
    
    @Test
    void login_unauthorized() throws Exception {
        LoginRequest req = new LoginRequest();
        req.setEmail("nonexistent@test.com");
        req.setPassword("wrongpassword");
        
        // Auth failure should map to 401 ideally or 400 depending on service
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest()); // usually BadCredentialsException -> 400 or 401
    }

    @Test
    void googleLogin_verifiedIdentity_returnsApplicationJwt() throws Exception {
        String email = "google" + System.currentTimeMillis() + "@test.com";
        when(googleTokenVerifier.verify(anyString())).thenReturn(
                new GoogleTokenVerifier.GoogleIdentity(
                        "google-subject-" + System.currentTimeMillis(),
                        email,
                        "Google Test User",
                        "https://example.test/avatar.png",
                        null));

        mockMvc.perform(post("/api/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"idToken\":\"verified-google-token\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(200))
                .andExpect(jsonPath("$.data.token").isNotEmpty())
                .andExpect(jsonPath("$.data.type").value("Bearer"));
    }

    @Test
    void googleLogin_invalidToken_returnsBadRequest() throws Exception {
        when(googleTokenVerifier.verify(anyString())).thenThrow(
                new IllegalArgumentException("Google ID token không hợp lệ"));

        mockMvc.perform(post("/api/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"idToken\":\"invalid-token\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void googleLogin_differentSubjectCannotTakeOverLinkedEmail() throws Exception {
        String email = "linked" + System.currentTimeMillis() + "@gmail.com";
        when(googleTokenVerifier.verify(anyString())).thenReturn(
                new GoogleTokenVerifier.GoogleIdentity(
                        "original-google-subject",
                        email,
                        "Original User",
                        null,
                        null),
                new GoogleTokenVerifier.GoogleIdentity(
                        "different-google-subject",
                        email,
                        "Different User",
                        null,
                        null));

        mockMvc.perform(post("/api/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"idToken\":\"first-token\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"idToken\":\"second-token\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400));
    }
}
