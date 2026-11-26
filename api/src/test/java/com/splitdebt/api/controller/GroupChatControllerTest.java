package com.splitdebt.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.splitdebt.api.config.LegalProperties;
import com.splitdebt.api.dto.consent.RegisterConsentsDto;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.security.JwtUtils;
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
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class GroupChatControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository users;

    @Autowired
    private ConsentService consentService;

    @Autowired
    private LegalProperties legalProperties;

    @Autowired
    private PasswordEncoder encoder;

    @Autowired
    private JwtUtils jwt;

    @MockBean
    private FcmPushService push;

    private String newAccount() {
        return account(UUID.randomUUID() + "@test.com");
    }

    private String account(String email) {
        if (!users.existsByEmail(email)) {
            User u = users.save(User.builder()
                    .email(email)
                    .fullName("Test User " + email)
                    .passwordHash(encoder.encode("Password123!"))
                    .build());
            consentService.recordRegistration(u, new RegisterConsentsDto(
                    legalProperties.getTermsVersion(), legalProperties.getPrivacyVersion(), true), "android", "1.0.0");
        }
        return email;
    }

    private long createGroup(String ownerEmail) throws Exception {
        String ownerToken = "Bearer " + jwt.generateJwtToken(ownerEmail);
        var created = mockMvc.perform(post("/api/groups")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Test Chat Group\"}"))
                .andExpect(status().isCreated())
                .andReturn();
        return objectMapper.readTree(created.getResponse().getContentAsString())
                .path("data").path("id").asLong();
    }

    private void addMember(long groupId, String ownerEmail, String memberEmail) throws Exception {
        String ownerToken = "Bearer " + jwt.generateJwtToken(ownerEmail);
        mockMvc.perform(post("/api/groups/" + groupId + "/members")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", memberEmail))))
                .andExpect(status().isCreated());
    }

    @Test
    void nonMember_cannotListOrSend() throws Exception {
        String owner = newAccount();
        String stranger = newAccount();
        long groupId = createGroup(owner);

        String strangerToken = "Bearer " + jwt.generateJwtToken(stranger);

        // GET should return 403
        mockMvc.perform(get("/api/groups/" + groupId + "/messages")
                        .header("Authorization", strangerToken))
                .andExpect(status().isForbidden());

        // POST should return 403
        String sendBody = objectMapper.writeValueAsString(Map.of(
                "content", "Hello from stranger",
                "clientMessageId", UUID.randomUUID().toString()
        ));
        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", strangerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(sendBody))
                .andExpect(status().isForbidden());
    }

    @Test
    void send_thenListLatest_ascendingOrder() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);

        for (int i = 1; i <= 3; i++) {
            String body = objectMapper.writeValueAsString(Map.of(
                    "content", "Message " + i,
                    "clientMessageId", UUID.randomUUID().toString()
            ));
            mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                            .header("Authorization", ownerToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(body))
                    .andExpect(status().isCreated());
        }

        mockMvc.perform(get("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.messages", hasSize(3)))
                .andExpect(jsonPath("$.data.messages[0].content", is("Message 1")))
                .andExpect(jsonPath("$.data.messages[1].content", is("Message 2")))
                .andExpect(jsonPath("$.data.messages[2].content", is("Message 3")))
                .andExpect(jsonPath("$.data.hasMore", is(false)));
    }

    @Test
    void duplicateClientMessageId_isIdempotent() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        String clientMsgId = UUID.randomUUID().toString();

        String body = objectMapper.writeValueAsString(Map.of(
                "content", "Same message",
                "clientMessageId", clientMsgId
        ));

        // First POST -> 201 Created
        var res1 = mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id", notNullValue()))
                .andReturn();

        long firstId = objectMapper.readTree(res1.getResponse().getContentAsString())
                .path("data").path("id").asLong();

        // Second POST with same clientMessageId -> 200 OK with same message ID
        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id", is((int) firstId)));

        // GET messages should still have size 1
        mockMvc.perform(get("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.messages", hasSize(1)));
    }

    @Test
    void blankOrTooLong_isRejected() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);

        // Blank content -> 400
        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "content", "   ",
                                "clientMessageId", UUID.randomUUID().toString()
                        ))))
                .andExpect(status().isBadRequest());

        // 2001 code points -> 400
        String tooLong = "a".repeat(2001);
        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "content", tooLong,
                                "clientMessageId", UUID.randomUUID().toString()
                        ))))
                .andExpect(status().isBadRequest());

        // 2000 emoji code points -> 201
        String emoji2000 = "😀".repeat(2000);
        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "content", emoji2000,
                                "clientMessageId", UUID.randomUUID().toString()
                        ))))
                .andExpect(status().isCreated());
    }

    @Test
    void invalidClientMessageId_isRejected() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);

        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "content", "Test message",
                                "clientMessageId", "abc"
                        ))))
                .andExpect(status().isBadRequest());
    }

    @Test
    void beforeAndAfterPaging() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);

        List<Long> msgIds = new ArrayList<>();
        for (int i = 1; i <= 35; i++) {
            var res = mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                            .header("Authorization", ownerToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of(
                                    "content", "Msg " + i,
                                    "clientMessageId", UUID.randomUUID().toString()
                            ))))
                    .andExpect(status().isCreated())
                    .andReturn();
            long id = objectMapper.readTree(res.getResponse().getContentAsString())
                    .path("data").path("id").asLong();
            msgIds.add(id);
        }

        // GET limit=30 -> 30 latest messages (from index 5 to 34), hasMore = true
        var resLatest = mockMvc.perform(get("/api/groups/" + groupId + "/messages?limit=30")
                        .header("Authorization", ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.messages", hasSize(30)))
                .andExpect(jsonPath("$.data.hasMore", is(true)))
                .andExpect(jsonPath("$.data.messages[0].content", is("Msg 6")))
                .andExpect(jsonPath("$.data.messages[29].content", is("Msg 35")))
                .andReturn();

        long smallestIdInLatest = objectMapper.readTree(resLatest.getResponse().getContentAsString())
                .path("data").path("messages").get(0).path("id").asLong();

        // GET before=smallestIdInLatest -> remaining 5 oldest messages (Msg 1 to Msg 5), hasMore = false
        mockMvc.perform(get("/api/groups/" + groupId + "/messages?before=" + smallestIdInLatest + "&limit=30")
                        .header("Authorization", ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.messages", hasSize(5)))
                .andExpect(jsonPath("$.data.hasMore", is(false)))
                .andExpect(jsonPath("$.data.messages[0].content", is("Msg 1")))
                .andExpect(jsonPath("$.data.messages[4].content", is("Msg 5")));

        // GET after=msgIds.get(32) (Msg 33) -> 2 messages (Msg 34 and Msg 35)
        long afterId = msgIds.get(32);
        mockMvc.perform(get("/api/groups/" + groupId + "/messages?after=" + afterId)
                        .header("Authorization", ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.messages", hasSize(2)))
                .andExpect(jsonPath("$.data.messages[0].content", is("Msg 34")))
                .andExpect(jsonPath("$.data.messages[1].content", is("Msg 35")));
    }

    @Test
    void beforeAndAfterTogether_isRejected() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);

        mockMvc.perform(get("/api/groups/" + groupId + "/messages?before=10&after=5")
                        .header("Authorization", ownerToken))
                .andExpect(status().isBadRequest());
    }

    @Test
    void limitIsCappedAt50() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);

        for (int i = 1; i <= 60; i++) {
            mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                            .header("Authorization", ownerToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of(
                                    "content", "Message " + i,
                                    "clientMessageId", UUID.randomUUID().toString()
                            ))))
                    .andExpect(status().isCreated());
        }

        mockMvc.perform(get("/api/groups/" + groupId + "/messages?limit=500")
                        .header("Authorization", ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.messages", hasSize(50)));
    }

    @Test
    void unreadCount_excludesOwnMessages() throws Exception {
        String owner = newAccount(); // User A
        String member = newAccount(); // User B
        long groupId = createGroup(owner);
        addMember(groupId, owner, member);

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        String memberToken = "Bearer " + jwt.generateJwtToken(member);

        // A sends 2 messages
        for (int i = 1; i <= 2; i++) {
            mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                            .header("Authorization", ownerToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of(
                                    "content", "Msg from A " + i,
                                    "clientMessageId", UUID.randomUUID().toString()
                            ))))
                    .andExpect(status().isCreated());
        }

        // B sends 1 message
        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", memberToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "content", "Msg from B 1",
                                "clientMessageId", UUID.randomUUID().toString()
                        ))))
                .andExpect(status().isCreated());

        // A views groups -> unreadMessageCount should be 1 (only B's message)
        mockMvc.perform(get("/api/groups")
                        .header("Authorization", ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == " + groupId + ")].unreadMessageCount").value(1));

        // B views groups -> unreadMessageCount should be 2 (A's 2 messages)
        mockMvc.perform(get("/api/groups")
                        .header("Authorization", memberToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == " + groupId + ")].unreadMessageCount").value(2));
    }

    @Test
    void markRead_resetsCount_andNeverMovesBack() throws Exception {
        String owner = newAccount(); // User A
        String member = newAccount(); // User B
        long groupId = createGroup(owner);
        addMember(groupId, owner, member);

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        String memberToken = "Bearer " + jwt.generateJwtToken(member);

        List<Long> msgIds = new ArrayList<>();
        for (int i = 1; i <= 3; i++) {
            var res = mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                            .header("Authorization", ownerToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of(
                                    "content", "Msg " + i,
                                    "clientMessageId", UUID.randomUUID().toString()
                            ))))
                    .andExpect(status().isCreated())
                    .andReturn();
            long id = objectMapper.readTree(res.getResponse().getContentAsString())
                    .path("data").path("id").asLong();
            msgIds.add(id);
        }

        // B marks read at latest message (id 3) -> 204
        mockMvc.perform(post("/api/groups/" + groupId + "/messages/read")
                        .header("Authorization", memberToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "lastReadMessageId", msgIds.get(2)
                        ))))
                .andExpect(status().isNoContent());

        // B views group -> count should be 0
        mockMvc.perform(get("/api/groups/" + groupId)
                        .header("Authorization", memberToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.unreadMessageCount", is(0)));

        // B attempts to mark read at earlier message (id 1) -> 204, but count remains 0
        mockMvc.perform(post("/api/groups/" + groupId + "/messages/read")
                        .header("Authorization", memberToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "lastReadMessageId", msgIds.get(0)
                        ))))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/groups/" + groupId)
                        .header("Authorization", memberToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.unreadMessageCount", is(0)));
    }

    @Test
    void markRead_foreignMessageId_isRejected() throws Exception {
        String owner = newAccount();
        long group1 = createGroup(owner);
        long group2 = createGroup(owner);
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);

        // Send a message in group 2
        var res = mockMvc.perform(post("/api/groups/" + group2 + "/messages")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "content", "Msg in group 2",
                                "clientMessageId", UUID.randomUUID().toString()
                        ))))
                .andExpect(status().isCreated())
                .andReturn();
        long msgIdGroup2 = objectMapper.readTree(res.getResponse().getContentAsString())
                .path("data").path("id").asLong();

        // Mark read in group 1 with message from group 2 -> 400 Bad Request
        mockMvc.perform(post("/api/groups/" + group1 + "/messages/read")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "lastReadMessageId", msgIdGroup2
                        ))))
                .andExpect(status().isBadRequest());
    }

    @Test
    void nonMember_cannotMarkRead() throws Exception {
        String owner = newAccount();
        String stranger = newAccount();
        long groupId = createGroup(owner);
        String strangerToken = "Bearer " + jwt.generateJwtToken(stranger);

        mockMvc.perform(post("/api/groups/" + groupId + "/messages/read")
                        .header("Authorization", strangerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "lastReadMessageId", 1L
                        ))))
                .andExpect(status().isForbidden());
    }

    @Test
    void deleteGroupWithMessages_succeeds() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);

        // Send 2 messages
        for (int i = 1; i <= 2; i++) {
            mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                            .header("Authorization", ownerToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of(
                                    "content", "Msg " + i,
                                    "clientMessageId", UUID.randomUUID().toString()
                            ))))
                    .andExpect(status().isCreated());
        }

        // Owner deletes group -> 200 OK (or 2xx)
        mockMvc.perform(delete("/api/groups/" + groupId)
                        .header("Authorization", ownerToken))
                .andExpect(status().is2xxSuccessful());
    }

    @Test
    void duplicateSend_doesNotPushTwice() throws Exception {
        String owner = newAccount();
        String member = newAccount();
        long groupId = createGroup(owner);
        addMember(groupId, owner, member);

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        String clientMsgId = UUID.randomUUID().toString();
        String body = objectMapper.writeValueAsString(Map.of(
                "content", "Message with push check",
                "clientMessageId", clientMsgId
        ));

        // First POST -> 201
        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated());

        // Second POST with same clientMessageId -> 200
        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());

        for (var sync : org.springframework.transaction.support.TransactionSynchronizationManager.getSynchronizations()) {
            sync.afterCommit();
        }

        long memberId = users.findByEmail(member).orElseThrow().getId();
        verify(push, times(1)).sendToUserTopic(eq(memberId), any(), any(), any());
    }

    @Test
    void newMember_startsWithZeroUnread() throws Exception {
        String owner = newAccount();
        String member = newAccount();
        long groupId = createGroup(owner);
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);

        for (int i = 1; i <= 3; i++) {
            mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                            .header("Authorization", ownerToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of(
                                    "content", "Before join " + i,
                                    "clientMessageId", UUID.randomUUID().toString()
                            ))))
                    .andExpect(status().isCreated());
        }

        addMember(groupId, owner, member);
        String memberToken = "Bearer " + jwt.generateJwtToken(member);

        mockMvc.perform(get("/api/groups")
                        .header("Authorization", memberToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].unreadMessageCount").value(0));

        mockMvc.perform(post("/api/groups/" + groupId + "/messages")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "content", "After join",
                                "clientMessageId", UUID.randomUUID().toString()
                        ))))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/groups")
                        .header("Authorization", memberToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].unreadMessageCount").value(1));
    }
}
