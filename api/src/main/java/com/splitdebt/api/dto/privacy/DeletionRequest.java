/**
 * Trách nhiệm file: Payload yêu cầu xoá tài khoản kèm mật khẩu xác nhận.
 */

package com.splitdebt.api.dto.privacy;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeletionRequest {
    private String password;
}

