package com.splitdebt.api.dto.chat;

public record SendMessageRequest(
        String content,
        String clientMessageId
) {}
