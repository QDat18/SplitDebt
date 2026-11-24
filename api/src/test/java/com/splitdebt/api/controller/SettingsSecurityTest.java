/**
 * Trách nhiệm file: Kiểm thử bảo mật phân quyền cho API Settings, kiểm tra quyền truy cập thành viên nhóm và chặn IDOR.
 */

package com.splitdebt.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import com.splitdebt.api.repository.GroupMemberRepository;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.security.JwtUtils;
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

import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class SettingsSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository users;

    @Autowired
    private GroupMemberRepository groupMemberRepository;

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
            users.save(User.builder()
                    .email(email)
                    .fullName("Test User")
                    .passwordHash(encoder.encode("Password123!"))
                    .build());
        }
        return email;
    }

    private long createGroup(String ownerEmail) throws Exception {
        String ownerToken = "Bearer " + jwt.generateJwtToken(ownerEmail);
        var created = mockMvc.perform(post("/api/groups")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Test Security Group\"}"))
                .andExpect(status().isCreated())
                .andReturn();
        return objectMapper.readTree(created.getResponse().getContentAsString())
                .path("data").path("id").asLong();
    }

    @Test
    void nonMember_cannotReadGroupSettings() throws Exception {
        String owner = newAccount();
        String stranger = newAccount();
        long groupId = createGroup(owner);

        String strangerToken = "Bearer " + jwt.generateJwtToken(stranger);
        mockMvc.perform(get("/api/settings/group/" + groupId)
                        .header("Authorization", strangerToken))
                .andExpect(status().isForbidden());
    }

    @Test
    void nonMember_cannotUpdateGroupSettings() throws Exception {
        String owner = newAccount();
        String stranger = newAccount();
        long groupId = createGroup(owner);

        String strangerToken = "Bearer " + jwt.generateJwtToken(stranger);
        String updateBody = objectMapper.writeValueAsString(Map.of(
                "requireApproval", true,
                "defaultCurrency", "USD"
        ));

        mockMvc.perform(put("/api/settings/group/" + groupId)
                        .header("Authorization", strangerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateBody))
                .andExpect(status().isForbidden());

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        mockMvc.perform(get("/api/settings/group/" + groupId)
                        .header("Authorization", ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.defaultCurrency", not("USD")));
    }

    @Test
    void plainMember_cannotUpdateGroupSettings() throws Exception {
        String owner = newAccount();
        String member = newAccount();
        long groupId = createGroup(owner);

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        mockMvc.perform(post("/api/groups/" + groupId + "/members")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", member))))
                .andExpect(status().isCreated());

        String memberToken = "Bearer " + jwt.generateJwtToken(member);
        String updateBody = objectMapper.writeValueAsString(Map.of(
                "requireApproval", true,
                "defaultCurrency", "USD"
        ));

        mockMvc.perform(put("/api/settings/group/" + groupId)
                        .header("Authorization", memberToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateBody))
                .andExpect(status().isForbidden());
    }

    @Test
    void member_canReadGroupSettings() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        mockMvc.perform(get("/api/settings/group/" + groupId)
                        .header("Authorization", ownerToken))
                .andExpect(status().isOk());
    }

    @Test
    void newUser_getsDefaultPreferences() throws Exception {
        String userEmail = newAccount();
        String userToken = "Bearer " + jwt.generateJwtToken(userEmail);

        mockMvc.perform(get("/api/settings/user/me")
                        .header("Authorization", userToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.language").value("VI"))
                .andExpect(jsonPath("$.currency").value("VND"))
                .andExpect(jsonPath("$.theme").value("LIGHT"));
    }

    @Test
    void legacyIdorRoute_isGone() throws Exception {
        String userEmail = newAccount();
        String otherEmail = newAccount();
        Long otherId = users.findByEmail(otherEmail).orElseThrow().getId();

        String userToken = "Bearer " + jwt.generateJwtToken(userEmail);
        mockMvc.perform(get("/api/v1/settings/user/" + otherId)
                        .header("Authorization", userToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void removedAdmin_cannotDeleteGroup() throws Exception {
        String owner = newAccount();
        String adminB = newAccount();
        long groupId = createGroup(owner);

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        mockMvc.perform(post("/api/groups/" + groupId + "/members")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", adminB,
                                "role", "ADMIN"
                        ))))
                .andExpect(status().isCreated());

        Long adminBId = users.findByEmail(adminB).orElseThrow().getId();
        var memberOpt = groupMemberRepository.findByGroupIdAndUserId(groupId, adminBId);
        org.junit.jupiter.api.Assertions.assertTrue(memberOpt.isPresent());
        var member = memberOpt.get();
        member.setStatus(GroupMemberStatus.INACTIVE);
        groupMemberRepository.save(member);

        String adminToken = "Bearer " + jwt.generateJwtToken(adminB);
        mockMvc.perform(delete("/api/groups/" + groupId)
                        .header("Authorization", adminToken))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminWhoLeft_cannotDeleteGroup() throws Exception {
        String owner = newAccount();
        String adminB = newAccount();
        long groupId = createGroup(owner);

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        mockMvc.perform(post("/api/groups/" + groupId + "/members")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", adminB,
                                "role", "ADMIN"
                        ))))
                .andExpect(status().isCreated());

        String adminToken = "Bearer " + jwt.generateJwtToken(adminB);
        mockMvc.perform(delete("/api/groups/" + groupId + "/members/me")
                        .header("Authorization", adminToken))
                .andExpect(status().isOk());

        mockMvc.perform(delete("/api/groups/" + groupId)
                        .header("Authorization", adminToken))
                .andExpect(status().isForbidden());
    }

    @Test
    void descriptionOver500Chars_isRejected() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        String longDescription = "a".repeat(501);
        String body = objectMapper.writeValueAsString(Map.of(
                "name", "Valid Group Name",
                "description", longDescription
        ));

        mockMvc.perform(put("/api/groups/" + groupId)
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void descriptionWithEmojiUnder500CodePoints_isAccepted() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        String emojiDescription = "😀".repeat(400);
        String body = objectMapper.writeValueAsString(Map.of(
                "name", "Emoji Group",
                "description", emojiDescription
        ));

        mockMvc.perform(put("/api/groups/" + groupId)
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());
    }

    @Test
    void description501CodePoints_isRejected() throws Exception {
        String owner = newAccount();
        long groupId = createGroup(owner);

        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        String emojiDescription = "😀".repeat(501);
        String body = objectMapper.writeValueAsString(Map.of(
                "name", "Emoji Group",
                "description", emojiDescription
        ));

        mockMvc.perform(put("/api/groups/" + groupId)
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createGroupWith400EmojiDescription_isCreated() throws Exception {
        String owner = newAccount();
        String ownerToken = "Bearer " + jwt.generateJwtToken(owner);
        String emojiDescription = "😀".repeat(400);
        String body = objectMapper.writeValueAsString(Map.of(
                "name", "Emoji Create Group",
                "description", emojiDescription
        ));

        mockMvc.perform(post("/api/groups")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated());
    }
}

