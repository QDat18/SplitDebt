package com.splitdebt.api.ledger;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties={
        "spring.datasource.url=jdbc:h2:mem:auth;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;NON_KEYWORDS=GROUPS;DB_CLOSE_DELAY=-1",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "splitdebt.jwt-secret=test-secret-long-enough-for-tests"
})
@AutoConfigureMockMvc
class AuthTests {
    @Autowired MockMvc mvc;

    @Test
    void healthAndAuthEndpointsArePublicButLedgerNeedsJwt() throws Exception {
        mvc.perform(get("/api/health")).andExpect(status().isOk());
        mvc.perform(post("/api/auth/register")
                .contentType("application/json")
                .content("{\"fullName\":\"Alice Example\",\"email\":\"alice@example.com\",\"password\":\"password123\",\"acceptedTerms\":true}"))
                .andExpect(status().isOk());
        mvc.perform(post("/api/auth/login")
                .contentType("application/json")
                .content("{\"email\":\"alice@example.com\",\"password\":\"password123\"}"))
                .andExpect(status().isOk());
        mvc.perform(get("/api/groups")).andExpect(status().isUnauthorized());
    }
}
