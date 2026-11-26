package com.splitdebt.api.dto.chat;

import java.time.LocalDateTime;

public record MessageDto(
        Long id,
        Long groupId,
        Long senderId,
        String senderName,
        String content,
        LocalDateTime createdAt,
        String clientMessageId
) {}

