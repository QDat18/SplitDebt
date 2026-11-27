/**
 * Trách nhiệm file: Kiểm thử luồng xoá tài khoản (ẩn danh hoá, kiểm tra công nợ, chuyển OWNER, giữ sổ nợ chung).
 */

package com.splitdebt.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.splitdebt.api.config.LegalProperties;
import com.splitdebt.api.dto.LoginRequest;
import com.splitdebt.api.dto.RegisterRequest;
import com.splitdebt.api.dto.consent.RegisterConsentsDto;
import com.splitdebt.api.dto.privacy.DeletionRequest;
import com.splitdebt.api.entity.*;
import com.splitdebt.api.entity.enums.GroupRole;
import com.splitdebt.api.repository.*;
import com.splitdebt.api.service.FcmPushService;
import com.splitdebt.api.service.SupabaseStorageService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class AccountDeletionControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private UserRepository userRepository;
    @Autowired private GroupRepository groupRepository;
    @Autowired private GroupMemberRepository groupMemberRepository;
    @Autowired private GroupMessageRepository groupMessageRepository;
    @Autowired private ExpenseRepository expenseRepository;
    @Autowired private SettlementRepository settlementRepository;
    @Autowired private UserConsentRepository userConsentRepository;
    @Autowired private FcmTokenRepository fcmTokenRepository;
    @Autowired private UserSettingRepository userSettingRepository;
    @Autowired private NotificationRepository notificationRepository;
    @Autowired private UserActivityLogRepository userActivityLogRepository;
    @Autowired private LegalProperties legalProperties;

    @MockBean private SupabaseStorageService supabaseStorageService;
    @MockBean private FcmPushService fcmPushService;

    private record TestUser(Long id, String email, String token) {}

    private TestUser register(String prefix) throws Exception {
        String email = prefix + "_" + System.nanoTime() + "@test.com";
        RegisterRequest req = new RegisterRequest();
        req.setFullName("User " + prefix);
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
        return new TestUser(id, email, token);
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

    private void addMember(String ownerToken, long groupId, String email, GroupRole role) throws Exception {
        mockMvc.perform(post("/api/groups/" + groupId + "/members")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", email, "role", role.name()))))
                .andExpect(status().isCreated());
    }

    @Test
    void wrongPassword_is400() throws Exception {
        TestUser a = register("wrongpw");
        DeletionRequest req = new DeletionRequest("WrongPass123!");

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.code").value("WRONG_PASSWORD"))
                .andExpect(jsonPath("$.message", containsString("Mật khẩu không đúng")));
    }

    @Test
    void outstandingBalance_is409WithGroups() throws Exception {
        TestUser a = register("debtor");
        TestUser b = register("creditor");
        long groupId = createGroup(b.token(), "Debt Group");
        addMember(b.token(), groupId, a.email(), GroupRole.MEMBER);

        var expense = Map.of(
                "groupId", groupId,
                "payerId", b.id(),
                "title", "Dinner",
                "totalAmount", 200000,
                "expenseDate", "2026-11-26",
                "splitType", "EQUAL",
                "participants", List.of(Map.of("userId", a.id()), Map.of("userId", b.id()))
        );
        mockMvc.perform(post("/api/v1/expenses")
                        .header("Authorization", "Bearer " + b.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(expense)))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.data.groups[0].name").value("Debt Group"))
                .andExpect(jsonPath("$.message", containsString("Bạn cần thanh toán hết công nợ trước khi xoá tài khoản.")));
    }

    @Test
    void success_anonymizesAndBlocksLogin() throws Exception {
        TestUser a = register("anon");
        User user = userRepository.findById(a.id()).orElseThrow();
        user.setPhone("0901234567");
        user.setAvatarUrl("https://example.supabase.co/storage/v1/object/public/Avatar/users/1/a.jpg");
        userRepository.save(user);

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isNoContent());

        verify(supabaseStorageService).deleteObject("https://example.supabase.co/storage/v1/object/public/Avatar/users/1/a.jpg");

        User updated = userRepository.findById(a.id()).orElseThrow();
        assertEquals("Người dùng đã xoá", updated.getFullName());
        assertTrue(updated.getEmail().endsWith("@deleted.invalid"));
        assertNull(updated.getPhone());
        assertNull(updated.getAvatarUrl());
        assertNotNull(updated.getDeletedAt());

        LoginRequest login = new LoginRequest();
        login.setEmail(a.email());
        login.setPassword("Password123!");
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(login)))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void ownerTransfer_toEarliestAdminOrMember() throws Exception {
        // Case 1: A OWNER, C MEMBER joins first, B ADMIN joins second -> B becomes OWNER
        TestUser a = register("owner1");
        TestUser b = register("admin1");
        TestUser c = register("member1");
        long g1 = createGroup(a.token(), "Transfer Admin");
        addMember(a.token(), g1, c.email(), GroupRole.MEMBER);
        addMember(a.token(), g1, b.email(), GroupRole.ADMIN);

        // Case 2: A2 OWNER, C2 MEMBER joins first, D2 MEMBER joins second (no ADMIN) -> C2 becomes OWNER
        TestUser a2 = register("owner2");
        TestUser c2 = register("member2");
        TestUser d2 = register("member3");
        long g2 = createGroup(a2.token(), "Transfer Member");
        addMember(a2.token(), g2, c2.email(), GroupRole.MEMBER);
        addMember(a2.token(), g2, d2.email(), GroupRole.MEMBER);

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isNoContent());

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a2.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isNoContent());

        assertEquals(GroupRole.OWNER, groupMemberRepository.findByGroupIdAndUserId(g1, b.id()).orElseThrow().getRole());
        assertEquals(GroupRole.OWNER, groupMemberRepository.findByGroupIdAndUserId(g2, c2.id()).orElseThrow().getRole());
    }

    @Test
    void soleOwnerGroup_isDeleted() throws Exception {
        TestUser a = register("sole");
        long g = createGroup(a.token(), "Sole Group");

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isNoContent());

        assertTrue(groupRepository.findById(g).isEmpty());
    }

    @Test
    void sharedExpensesKept_balancesUnchanged() throws Exception {
        TestUser a = register("shareda");
        TestUser b = register("sharedb");
        TestUser c = register("sharedc");
        long g = createGroup(a.token(), "Shared Group");
        addMember(a.token(), g, b.email(), GroupRole.MEMBER);
        addMember(a.token(), g, c.email(), GroupRole.MEMBER);

        // B pays 100000 split between B and C (A has 0 balance)
        var expense = Map.of(
                "groupId", g,
                "payerId", b.id(),
                "title", "Coffee",
                "totalAmount", 100000,
                "expenseDate", "2026-11-26",
                "splitType", "EQUAL",
                "participants", List.of(Map.of("userId", b.id()), Map.of("userId", c.id()))
        );
        mockMvc.perform(post("/api/v1/expenses")
                        .header("Authorization", "Bearer " + b.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(expense)))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/v1/expenses/group/" + g)
                        .header("Authorization", "Bearer " + b.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));

        mockMvc.perform(get("/api/groups/" + g + "/debts")
                        .param("userId", c.id().toString())
                        .header("Authorization", "Bearer " + c.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalToPay").value(50000));
    }

    @Test
    void messagesRedacted_consentsKept() throws Exception {
        TestUser a = register("redact");
        long g = createGroup(a.token(), "Msg Group");
        TestUser b = register("other");
        addMember(a.token(), g, b.email(), GroupRole.MEMBER);

        mockMvc.perform(post("/api/groups/" + g + "/messages")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "content", "Secret message",
                                "clientMessageId", UUID.randomUUID().toString()
                        ))))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isNoContent());

        List<GroupMessage> msgs = groupMessageRepository.findBySenderIdOrderByIdAsc(a.id());
        assertEquals(1, msgs.size());
        assertEquals("Tin nhắn đã bị xoá", msgs.get(0).getContent());
        assertEquals(3, userConsentRepository.findByUserIdOrderByIdAsc(a.id()).size());
    }

    @Test
    void personalTablesCleared() throws Exception {
        TestUser a = register("clear");
        User user = userRepository.findById(a.id()).orElseThrow();
        fcmTokenRepository.save(FcmToken.builder().user(user).token("fcm-" + a.id()).platform("android").build());
        userSettingRepository.save(UserSetting.builder().user(user).build());
        notificationRepository.save(Notification.builder().user(user).title("T").content("C").type("INFO").build());
        userActivityLogRepository.save(UserActivityLog.builder().userId(a.id()).action("TEST").description("D").build());

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isNoContent());

        assertTrue(fcmTokenRepository.findByUserId(a.id()).isEmpty());
        assertTrue(userSettingRepository.findByUserId(a.id()).isEmpty());
        assertTrue(notificationRepository.findByUserIdOrderByCreatedAtDesc(a.id()).isEmpty());
        assertTrue(userActivityLogRepository.findByUserIdOrderByCreatedAtDesc(a.id()).isEmpty());
    }

    @Test
    void oldJwt_rejected() throws Exception {
        TestUser a = register("oldjwt");

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + a.token()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void soleOwnerGroupWithExpenses_isPurged() throws Exception {
        TestUser a = register("soleexp");
        long g = createGroup(a.token(), "Sole Expense Group");

        var expense = Map.of(
                "groupId", g,
                "payerId", a.id(),
                "title", "Solo coffee",
                "totalAmount", 50000,
                "expenseDate", "2026-11-26",
                "splitType", "EQUAL",
                "participants", List.of(Map.of("userId", a.id()))
        );
        mockMvc.perform(post("/api/v1/expenses")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(expense)))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isNoContent());

        assertTrue(groupRepository.findById(g).isEmpty());
        assertTrue(expenseRepository.findByGroupId(g).isEmpty());
        assertTrue(settlementRepository.findByGroupId(g).isEmpty());
    }

    @Test
    void soleOwnerWithFormerMembers_isPurged() throws Exception {
        TestUser a = register("soleformer_a");
        TestUser b = register("soleformer_b");
        long g = createGroup(a.token(), "Former Member Group");
        addMember(a.token(), g, b.email(), GroupRole.MEMBER);

        var expense = Map.of(
                "groupId", g,
                "payerId", a.id(),
                "title", "Lunch",
                "totalAmount", 100000,
                "expenseDate", "2026-11-26",
                "splitType", "EQUAL",
                "participants", List.of(Map.of("userId", a.id()), Map.of("userId", b.id()))
        );
        mockMvc.perform(post("/api/v1/expenses")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(expense)))
                .andExpect(status().isCreated());

        MvcResult sRes = mockMvc.perform(post("/api/groups/" + g + "/settlements")
                        .param("userId", b.id().toString())
                        .header("Authorization", "Bearer " + b.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "debtorId", b.id(),
                                "creditorId", a.id(),
                                "amount", 50000
                        ))))
                .andExpect(status().isOk())
                .andReturn();
        long sId = objectMapper.readTree(sRes.getResponse().getContentAsString()).path("data").path("id").asLong();

        mockMvc.perform(post("/api/groups/" + g + "/settlements/" + sId + "/pay")
                        .header("Authorization", "Bearer " + b.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "debtorUserId", b.id(),
                                "paymentMethod", "CASH"
                        ))))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/groups/" + g + "/settlements/" + sId + "/confirm")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        mockMvc.perform(delete("/api/groups/" + g + "/members/me")
                        .header("Authorization", "Bearer " + b.token()))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/users/me/deletion")
                        .header("Authorization", "Bearer " + a.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new DeletionRequest("Password123!"))))
                .andExpect(status().isNoContent());

        assertTrue(groupRepository.findById(g).isEmpty());
        assertTrue(expenseRepository.findByGroupId(g).isEmpty());
        assertTrue(settlementRepository.findByGroupId(g).isEmpty());
    }
}

