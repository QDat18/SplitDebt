/**
 * Trách nhiệm file: Payload cập nhật hoặc đồng ý lại các điều khoản.
 */

package com.splitdebt.api.dto.consent;

import com.splitdebt.api.entity.enums.ConsentSource;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConsentUpdateRequest {
    private List<ConsentItemDto> items;
    private ConsentSource source;
    private String platform;
    private String appVersion;
}

