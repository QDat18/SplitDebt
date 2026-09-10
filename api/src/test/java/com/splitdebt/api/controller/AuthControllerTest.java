package com.splitdebt.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.splitdebt.api.dto.LoginRequest;
import com.splitdebt.api.dto.RegisterRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

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
}
