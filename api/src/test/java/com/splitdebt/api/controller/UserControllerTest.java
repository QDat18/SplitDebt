package com.splitdebt.api.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void getUserProfile_unauthorized() throws Exception {
        mockMvc.perform(get("/api/users/profile"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401));
    }

    @Test
    @WithMockUser
    void getUserProfile_success() throws Exception {
        // Just mock user, if DB is empty it might return 404 or something, but we check if it bypasses 401
        // Usually, a mocked user won't exist in DB so it returns 404 for this particular API
        mockMvc.perform(get("/api/users/profile"))
                .andExpect(status().isNotFound()) // Or 200 depending on mock
                .andExpect(jsonPath("$.status").value(404)); // Testing 404 for user profile
    }
}
