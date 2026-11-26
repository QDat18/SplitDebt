package com.splitdebt.api.dto.chat;

import java.util.List;

public record MessagePageDto(
        List<MessageDto> messages,
        boolean hasMore
) {}

