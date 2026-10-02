package com.splitdebt.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.splitdebt.api.dto.AddMemberRequestDto;
import com.splitdebt.api.dto.GroupRequestDto;
import com.splitdebt.api.entity.enums.GroupRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@org.springframework.transaction.annotation.Transactional
public class GroupControllerTest {
    @Autowired private com.splitdebt.api.repository.UserRepository users;
    @Autowired private org.springframework.security.crypto.password.PasswordEncoder encoder;
    @Autowired private com.splitdebt.api.security.JwtUtils jwt;
    @org.springframework.boot.test.mock.mockito.MockBean
    private com.splitdebt.api.service.FcmPushService push;

    @Test
    void jwtGroupExpenseAndTwoWaySettlement() throws Exception {
        String owner = newAccount();
        String debtor = newAccount();
        Long ownerId = users.findByEmail(owner).orElseThrow().getId();
        Long debtorId = users.findByEmail(debtor).orElseThrow().getId();
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        String debtorToken = "Bearer " + jwt.generateJwtToken(debtor);
        var created = mockMvc.perform(post("/api/groups").header("Authorization", ownerToken)
                .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"Integration group\"}"))
                .andExpect(status().isCreated()).andReturn();
        long groupId = objectMapper.readTree(created.getResponse().getContentAsString()).path("data").path("id").asLong();
        mockMvc.perform(post("/api/groups/" + groupId + "/members").header("Authorization", ownerToken)
                .contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(java.util.Map.of("email", debtor))))
                .andExpect(status().isCreated());
        var expense = java.util.Map.of("groupId", groupId, "payerId", ownerId,
                "title", "Dinner", "totalAmount", 200000, "expenseDate", "2026-09-12", "splitType", "EQUAL",
                "participants", java.util.List.of(java.util.Map.of("userId", ownerId), java.util.Map.of("userId", debtorId)));
        mockMvc.perform(post("/api/v1/expenses").header("Authorization", ownerToken)
                .contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(expense)))
                .andExpect(status().isCreated());
        mockMvc.perform(get("/api/groups/" + groupId + "/debts").param("userId", debtorId.toString())
                .header("Authorization", debtorToken)).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalToPay").value(100000));
        var payment = mockMvc.perform(post("/api/groups/" + groupId + "/settlements")
                .param("userId", debtorId.toString()).header("Authorization", debtorToken)
                .contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(
                        java.util.Map.of("debtorId", debtorId, "creditorId", ownerId, "amount", 100000))))
                .andExpect(status().isOk()).andReturn();
        long settlementId = objectMapper.readTree(payment.getResponse().getContentAsString()).path("data").path("id").asLong();
        String path = "/api/groups/" + groupId + "/settlements/" + settlementId;
        String payBody = objectMapper.writeValueAsString(java.util.Map.of("debtorUserId", debtorId, "paymentMethod", "CASH"));
        mockMvc.perform(post(path + "/pay").header("Authorization", ownerToken)
                .contentType(MediaType.APPLICATION_JSON).content(payBody)).andExpect(status().isBadRequest());
        mockMvc.perform(post(path + "/pay").header("Authorization", debtorToken)
                .contentType(MediaType.APPLICATION_JSON).content(payBody)).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("PAID"));
        mockMvc.perform(get("/api/groups/" + groupId + "/debts").param("userId", debtorId.toString())
                .header("Authorization", debtorToken)).andExpect(jsonPath("$.data.totalToPay").value(100000));
        mockMvc.perform(post(path + "/confirm").header("Authorization", ownerToken)
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value("CONFIRMED"));
        mockMvc.perform(get("/api/groups/" + groupId + "/debts").param("userId", debtorId.toString())
                .header("Authorization", debtorToken)).andExpect(jsonPath("$.data.totalToPay").value(0));
        mockMvc.perform(get("/api/groups/" + groupId + "/debts").param("userId", ownerId.toString())
                .header("Authorization", ownerToken)).andExpect(jsonPath("$.data.totalToReceive").value(0));
    }

    private String newAccount() {
        return account(java.util.UUID.randomUUID() + "@test.com");
    }
    private String account(String email) {
        if (!users.existsByEmail(email)) users.save(com.splitdebt.api.entity.User.builder()
            .email(email).fullName("Test User").passwordHash(encoder.encode("Password123!")).build());
        return email;
    }
    private String identity(String value) {
        return value.contains("@") ? value : users.findById(Long.parseLong(value)).orElseThrow().getEmail();
    }
    @org.junit.jupiter.api.BeforeEach void existingMembers() {
        account("thanhvien_a@gmail.com");
        account("member_test_b@gmail.com");
        account("member_leave_c@gmail.com");
    }


    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("CASE 1 & 2: Create group and verify creator becomes OWNER")
    void testCreateGroup_Success() throws Exception {
        String userId = newAccount();
        GroupRequestDto dto = GroupRequestDto.builder()
                .name("Nhóm Đi Phượt Đà Lạt")
                .description("Mô tả chi tiêu Đà Lạt")
                .build();

        mockMvc.perform(post("/api/groups")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(userId.toString())))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.name", is("Nhóm Đi Phượt Đà Lạt")))
                .andExpect(jsonPath("$.data.currentUserRole", is("OWNER")))
                .andExpect(jsonPath("$.data.memberCount", is(1)));
    }

    @Test
    @DisplayName("CASE 3 & 4: Admin adds member & duplicate member check")
    void testAddMember_AndDuplicateCheck() throws Exception {
        String ownerId = newAccount();
        GroupRequestDto dto = GroupRequestDto.builder()
                .name("Phòng trọ 402")
                .description("Tiền nhà và điện nước")
                .build();

        MvcResult result = mockMvc.perform(post("/api/groups")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(ownerId.toString())))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isCreated())
                .andReturn();

        String responseStr = result.getResponse().getContentAsString();
        String groupId = objectMapper.readTree(responseStr).get("data").get("id").asText();

        // Add member
        AddMemberRequestDto addDto = AddMemberRequestDto.builder()
                .email("thanhvien_a@gmail.com")
                .role(GroupRole.MEMBER)
                .build();

        mockMvc.perform(post("/api/groups/" + groupId + "/members")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(ownerId.toString())))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(addDto)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.email", is("thanhvien_a@gmail.com")));

        // Try adding same member again -> expect HTTP 400 Bad Request
        mockMvc.perform(post("/api/groups/" + groupId + "/members")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(ownerId.toString())))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(addDto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("already a member")));
    }

    @Test
    @DisplayName("CASE 5 & 6: User sees joined groups and does not see unjoined groups")
    void testGetUserGroups_Isolation() throws Exception {
        String userA = newAccount();
        String userB = newAccount();

        // User A creates Group A
        GroupRequestDto dtoA = GroupRequestDto.builder().name("Group A").build();
        mockMvc.perform(post("/api/groups")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(userA.toString())))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dtoA)))
                .andExpect(status().isCreated());

        // User B creates Group B
        GroupRequestDto dtoB = GroupRequestDto.builder().name("Group B").build();
        mockMvc.perform(post("/api/groups")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(userB.toString())))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dtoB)))
                .andExpect(status().isCreated());

        // Query User A groups -> only Group A
        mockMvc.perform(get("/api/groups")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(userA.toString()))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].name", is("Group A")));
    }

    @Test
    @DisplayName("CASE 7: Non-admin member cannot execute admin API")
    void testMemberForbiddenActions() throws Exception {
        String ownerId = newAccount();
        String memberId = newAccount();

        // Create group
        GroupRequestDto dto = GroupRequestDto.builder().name("Group Admin Test").build();
        MvcResult result = mockMvc.perform(post("/api/groups")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(ownerId.toString())))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isCreated())
                .andReturn();

        String groupId = objectMapper.readTree(result.getResponse().getContentAsString()).get("data").get("id").asText();

        // Add memberId to group
        AddMemberRequestDto addDto = AddMemberRequestDto.builder().email("member_test_b@gmail.com").role(GroupRole.MEMBER).build();
        MvcResult addMemberResult = mockMvc.perform(post("/api/groups/" + groupId + "/members")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(ownerId.toString())))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(addDto)))
                .andExpect(status().isCreated())
                .andReturn();

        String memberUserId = objectMapper.readTree(addMemberResult.getResponse().getContentAsString()).get("data").get("userId").asText();

        // Member tries to update group -> Expect 403 Forbidden
        GroupRequestDto updateDto = GroupRequestDto.builder().name("Unauthorized Update").build();
        mockMvc.perform(put("/api/groups/" + groupId)
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(memberUserId)))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(updateDto)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("CASE 8 & 9: Member leaves group and group disappears from user list")
    void testLeaveGroup() throws Exception {
        String ownerId = newAccount();

        // Create group
        GroupRequestDto dto = GroupRequestDto.builder().name("Group Leave Test").build();
        MvcResult result = mockMvc.perform(post("/api/groups")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(ownerId.toString())))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isCreated())
                .andReturn();

        String groupId = objectMapper.readTree(result.getResponse().getContentAsString()).get("data").get("id").asText();

        // Add member
        AddMemberRequestDto addDto = AddMemberRequestDto.builder().email("member_leave_c@gmail.com").role(GroupRole.MEMBER).build();
        MvcResult addMemberResult = mockMvc.perform(post("/api/groups/" + groupId + "/members")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(ownerId.toString())))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(addDto)))
                .andExpect(status().isCreated())
                .andReturn();

        String memberUserId = objectMapper.readTree(addMemberResult.getResponse().getContentAsString()).get("data").get("userId").asText();

        // Member leaves group
        mockMvc.perform(delete("/api/groups/" + groupId + "/members/me")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(memberUserId))))
                .andExpect(status().isOk());

        // Member checks group list -> 0 groups
        mockMvc.perform(get("/api/groups")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(identity(memberUserId))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(0)));
    }
}
