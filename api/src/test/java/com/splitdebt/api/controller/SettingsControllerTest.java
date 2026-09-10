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
public class SettingsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void getSettings_unauthorized() throws Exception {
        mockMvc.perform(get("/api/settings/1")) // group 1 settings
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401));
    }

    @Test
    @WithMockUser
    void getSettings_notFound() throws Exception {
        // Group doesn't exist, should return 404
        mockMvc.perform(get("/api/settings/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404)); // Depends on business logic, assuming 404 is thrown
    }
}
