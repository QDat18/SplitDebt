package com.splitdebt.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.splitdebt.api.dto.AddMemberRequestDto;
import com.splitdebt.api.dto.GroupRequestDto;
import com.splitdebt.api.entity.GroupRole;
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
public class GroupControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("CASE 1 & 2: Create group and verify creator becomes OWNER")
    void testCreateGroup_Success() throws Exception {
        UUID userId = UUID.randomUUID();
        GroupRequestDto dto = GroupRequestDto.builder()
                .name("Nhóm Đi Phượt Đà Lạt")
                .description("Mô tả chi tiêu Đà Lạt")
                .build();

        mockMvc.perform(post("/api/groups")
                .header("X-User-Id", userId.toString())
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
        UUID ownerId = UUID.randomUUID();
        GroupRequestDto dto = GroupRequestDto.builder()
                .name("Phòng trọ 402")
                .description("Tiền nhà và điện nước")
                .build();

        MvcResult result = mockMvc.perform(post("/api/groups")
                .header("X-User-Id", ownerId.toString())
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
                .header("X-User-Id", ownerId.toString())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(addDto)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.email", is("thanhvien_a@gmail.com")));

        // Try adding same member again -> expect HTTP 400 Bad Request
        mockMvc.perform(post("/api/groups/" + groupId + "/members")
                .header("X-User-Id", ownerId.toString())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(addDto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("already a member")));
    }

    @Test
    @DisplayName("CASE 5 & 6: User sees joined groups and does not see unjoined groups")
    void testGetUserGroups_Isolation() throws Exception {
        UUID userA = UUID.randomUUID();
        UUID userB = UUID.randomUUID();

        // User A creates Group A
        GroupRequestDto dtoA = GroupRequestDto.builder().name("Group A").build();
        mockMvc.perform(post("/api/groups")
                .header("X-User-Id", userA.toString())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dtoA)))
                .andExpect(status().isCreated());

        // User B creates Group B
        GroupRequestDto dtoB = GroupRequestDto.builder().name("Group B").build();
        mockMvc.perform(post("/api/groups")
                .header("X-User-Id", userB.toString())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dtoB)))
                .andExpect(status().isCreated());

        // Query User A groups -> only Group A
        mockMvc.perform(get("/api/groups")
                .header("X-User-Id", userA.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].name", is("Group A")));
    }

    @Test
    @DisplayName("CASE 7: Non-admin member cannot execute admin API")
    void testMemberForbiddenActions() throws Exception {
        UUID ownerId = UUID.randomUUID();
        UUID memberId = UUID.randomUUID();

        // Create group
        GroupRequestDto dto = GroupRequestDto.builder().name("Group Admin Test").build();
        MvcResult result = mockMvc.perform(post("/api/groups")
                .header("X-User-Id", ownerId.toString())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isCreated())
                .andReturn();

        String groupId = objectMapper.readTree(result.getResponse().getContentAsString()).get("data").get("id").asText();

        // Add memberId to group
        AddMemberRequestDto addDto = AddMemberRequestDto.builder().email("member_test_b@gmail.com").role(GroupRole.MEMBER).build();
        MvcResult addMemberResult = mockMvc.perform(post("/api/groups/" + groupId + "/members")
                .header("X-User-Id", ownerId.toString())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(addDto)))
                .andExpect(status().isCreated())
                .andReturn();

        String memberUserId = objectMapper.readTree(addMemberResult.getResponse().getContentAsString()).get("data").get("userId").asText();

        // Member tries to update group -> Expect 403 Forbidden
        GroupRequestDto updateDto = GroupRequestDto.builder().name("Unauthorized Update").build();
        mockMvc.perform(put("/api/groups/" + groupId)
                .header("X-User-Id", memberUserId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(updateDto)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("CASE 8 & 9: Member leaves group and group disappears from user list")
    void testLeaveGroup() throws Exception {
        UUID ownerId = UUID.randomUUID();

        // Create group
        GroupRequestDto dto = GroupRequestDto.builder().name("Group Leave Test").build();
        MvcResult result = mockMvc.perform(post("/api/groups")
                .header("X-User-Id", ownerId.toString())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isCreated())
                .andReturn();

        String groupId = objectMapper.readTree(result.getResponse().getContentAsString()).get("data").get("id").asText();

        // Add member
        AddMemberRequestDto addDto = AddMemberRequestDto.builder().email("member_leave_c@gmail.com").role(GroupRole.MEMBER).build();
        MvcResult addMemberResult = mockMvc.perform(post("/api/groups/" + groupId + "/members")
                .header("X-User-Id", ownerId.toString())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(addDto)))
                .andExpect(status().isCreated())
                .andReturn();

        String memberUserId = objectMapper.readTree(addMemberResult.getResponse().getContentAsString()).get("data").get("userId").asText();

        // Member leaves group
        mockMvc.perform(delete("/api/groups/" + groupId + "/members/me")
                .header("X-User-Id", memberUserId))
                .andExpect(status().isOk());

        // Member checks group list -> 0 groups
        mockMvc.perform(get("/api/groups")
                .header("X-User-Id", memberUserId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(0)));
    }
}
