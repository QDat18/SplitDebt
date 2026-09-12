package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import com.splitdebt.api.repository.GroupMemberRepository;
import com.splitdebt.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/groups")
@RequiredArgsConstructor
public class GroupController {
    private final GroupMemberRepository members;
    private final UserRepository users;

    public record GroupSummary(Long id, String name) {}

    @GetMapping
    @Transactional(readOnly = true)
    public ApiResponse<List<GroupSummary>> list(Authentication authentication) {
        var user = users.findByEmail(authentication.getName()).orElseThrow();
        var groups = members.findByUserIdAndStatus(user.getId(), GroupMemberStatus.ACTIVE)
                .stream().map(member -> new GroupSummary(
                        member.getGroup().getId(), member.getGroup().getName())).toList();
        return ApiResponse.success(groups, "Tải nhóm thành công");
    }
}
