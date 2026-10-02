/**
 * Trách nhiệm file: Biểu diễn hoặc xử lý lỗi nghiệp vụ Group Permission Exception theo phản hồi API thống nhất.
 */

package com.splitdebt.api.exception;

public class GroupPermissionException extends RuntimeException {
    public GroupPermissionException(String message) {
        super(message);
    }
}
