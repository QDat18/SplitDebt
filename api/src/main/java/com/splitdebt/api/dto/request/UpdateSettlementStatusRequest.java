/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Update Settlement Status Request nhận từ API.
 */

package com.splitdebt.api.dto.request;

import com.splitdebt.api.entity.enums.SettlementStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateSettlementStatusRequest {

    private SettlementStatus status;
}
