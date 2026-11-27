package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.chat.MessageDto;
import com.splitdebt.api.dto.chat.MessagePageDto;
import com.splitdebt.api.dto.chat.SendMessageRequest;
import com.splitdebt.api.exception.UserNotFoundException;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.GroupChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/groups/{groupId}/messages")
@RequiredArgsConstructor
@Tag(name = "Group Chat", description = "Các API nhắn tin trong nhóm chi tiêu")
public class GroupChatController {

    private final GroupChatService groupChatService;
    private final UserRepository userRepository;

    private Long resolveCurrentUserId() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("Không tìm thấy tài khoản"))
                .getId();
    }

    @GetMapping
    @Operation(summary = "Lấy danh sách tin nhắn trong nhóm")
    public ResponseEntity<ApiResponse<MessagePageDto>> listMessages(
            @PathVariable Long groupId,
            @RequestParam(required = false) Long before,
            @RequestParam(required = false) Long after,
            @RequestParam(required = false, defaultValue = "30") Integer limit
    ) {
        Long userId = resolveCurrentUserId();
        MessagePageDto dto = groupChatService.list(groupId, userId, before, after, limit);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    @PostMapping
    @Operation(summary = "Gửi tin nhắn vào nhóm")
    public ResponseEntity<ApiResponse<MessageDto>> sendMessage(
            @PathVariable Long groupId,
            @RequestBody SendMessageRequest request
    ) {
        Long userId = resolveCurrentUserId();
        GroupChatService.SendResult result = groupChatService.send(groupId, userId, request);
        if (result.created()) {
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.ok("Tin nhắn đã được gửi", result.message()));
        } else {
            return ResponseEntity.ok(ApiResponse.ok("Tin nhắn đã tồn tại", result.message()));
        }
    }

    @PostMapping("/read")
    @Operation(summary = "Đánh dấu đã đọc tin nhắn trong nhóm")
    public ResponseEntity<Void> markRead(
            @PathVariable Long groupId,
            @RequestBody java.util.Map<String, Long> body
    ) {
        Long userId = resolveCurrentUserId();
        Long lastReadMessageId = body != null ? body.get("lastReadMessageId") : null;
        groupChatService.markRead(groupId, userId, lastReadMessageId);
        return ResponseEntity.noContent().build();
    }
}
