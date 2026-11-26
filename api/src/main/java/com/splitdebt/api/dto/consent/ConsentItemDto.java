/**
 * Trách nhiệm file: Một mục đồng ý trong yêu cầu cập nhật đồng ý.
 */

package com.splitdebt.api.dto.consent;

import com.splitdebt.api.entity.enums.ConsentType;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConsentItemDto {
    private ConsentType type;
    private Boolean granted;
    private String version;
}

