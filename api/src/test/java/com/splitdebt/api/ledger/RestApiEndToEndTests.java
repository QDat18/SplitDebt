package com.splitdebt.api.ledger;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class RestApiEndToEndTests {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private String email(String prefix) {
        return prefix + "." + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
    }

    private JsonNode json(MvcResult result) throws Exception {
        return mapper.readTree(result.getResponse().getContentAsString());
    }

    private void register(String name, String email) throws Exception {
        mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "fullName", name,
                                "email", email,
                                "password", "password123",
                                "acceptedTerms", true))))
                .andExpect(status().isOk());
    }

    private String login(String email) throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "email", email,
                                "password", "password123"))))
                .andExpect(status().isOk()).andReturn();
        return json(result).get("token").asText();
    }

    @Test
    void completeUserJourneyWorksThroughRestApi() throws Exception {
        mvc.perform(get("/api/health")).andExpect(status().isOk());

        String ownerEmail = email("owner");
        String memberEmail = email("member");
        String outsiderEmail = email("outsider");
        register("Owner Person", ownerEmail);
        register("Member Person", memberEmail);
        register("Outsider Person", outsiderEmail);
        String ownerToken = login(ownerEmail);
        String memberToken = login(memberEmail);
        String outsiderToken = login(outsiderEmail);

        JsonNode ownerProfile = json(mvc.perform(get("/api/me").header("Authorization", "Bearer " + ownerToken))
                .andExpect(status().isOk()).andReturn());
        JsonNode memberProfile = json(mvc.perform(get("/api/me").header("Authorization", "Bearer " + memberToken))
                .andExpect(status().isOk()).andReturn());
        long ownerId = ownerProfile.get("id").asLong();
        long memberId = memberProfile.get("id").asLong();

        JsonNode group = json(mvc.perform(post("/api/groups")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "name", "REST Trip",
                                "description", "End-to-end test",
                                "currency", "VND"))))
                .andExpect(status().isOk()).andReturn());
        long groupId = group.get("id").asLong();
        String inviteCode = group.get("inviteCode").asText();

        mvc.perform(post("/api/groups/join")
                        .header("Authorization", "Bearer " + memberToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("inviteCode", inviteCode))))
                .andExpect(status().isOk());

        mvc.perform(get("/api/groups/{id}", groupId).header("Authorization", "Bearer " + outsiderToken))
                .andExpect(status().isNotFound());

        Map<String, Object> expensePayload = Map.of(
                "title", "Dinner",
                "totalAmount", 10_000,
                "payerId", ownerId,
                "expenseDate", LocalDate.now().toString(),
                "splitType", "EQUAL",
                "participants", List.of(Map.of("userId", ownerId), Map.of("userId", memberId)),
                "items", List.of());
        JsonNode expense = json(mvc.perform(post("/api/groups/{id}/expenses", groupId)
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(expensePayload)))
                .andExpect(status().isOk()).andReturn());
        assertEquals(10_000L, expense.get("amount").asLong());

        JsonNode detailBefore = json(mvc.perform(get("/api/groups/{id}", groupId)
                        .header("Authorization", "Bearer " + memberToken))
                .andExpect(status().isOk()).andReturn());
        assertEquals(-5_000L, detailBefore.get("balances").get(Long.toString(memberId)).asLong());
        assertEquals(5_000L, detailBefore.get("balances").get(Long.toString(ownerId)).asLong());
        assertEquals(1, detailBefore.get("suggestions").size());

        JsonNode paid = json(mvc.perform(post("/api/groups/{id}/settlements", groupId)
                        .header("Authorization", "Bearer " + memberToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "creditorId", ownerId,
                                "amount", 5_000,
                                "paymentMethod", "BANK_TRANSFER"))))
                .andExpect(status().isOk()).andReturn());
        assertEquals("PAID", paid.get("status").asText());
        long settlementId = paid.get("id").asLong();

        JsonNode whilePending = json(mvc.perform(get("/api/groups/{id}", groupId)
                        .header("Authorization", "Bearer " + memberToken))
                .andExpect(status().isOk()).andReturn());
        assertEquals(0, whilePending.get("suggestions").size(),
                "A pending payment should not be suggested again.");

        JsonNode confirmed = json(mvc.perform(post("/api/settlements/{id}/confirm", settlementId)
                        .header("Authorization", "Bearer " + ownerToken))
                .andExpect(status().isOk()).andReturn());
        assertEquals("CONFIRMED", confirmed.get("status").asText());

        JsonNode detailAfter = json(mvc.perform(get("/api/groups/{id}", groupId)
                        .header("Authorization", "Bearer " + ownerToken))
                .andExpect(status().isOk()).andReturn());
        assertEquals(0L, detailAfter.get("balances").get(Long.toString(memberId)).asLong());
        assertEquals(0L, detailAfter.get("balances").get(Long.toString(ownerId)).asLong());

        JsonNode stats = json(mvc.perform(get("/api/groups/{id}/statistics", groupId)
                        .param("range", "DAY")
                        .header("Authorization", "Bearer " + ownerToken))
                .andExpect(status().isOk()).andReturn());
        assertEquals(10_000L, stats.get("totalExpense").asLong());

        JsonNode notifications = json(mvc.perform(get("/api/notifications")
                        .header("Authorization", "Bearer " + memberToken))
                .andExpect(status().isOk()).andReturn());
        assertTrue(notifications.isArray());
        assertTrue(notifications.size() >= 1);

        JsonNode activity = json(mvc.perform(get("/api/activity")
                        .param("limit", "10")
                        .header("Authorization", "Bearer " + ownerToken))
                .andExpect(status().isOk()).andReturn());
        assertTrue(activity.get("items").size() >= 2, "Expense and settlement should both appear in activity.");
    }
}
