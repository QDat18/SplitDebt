/**
 * Trách nhiệm file: Biểu diễn hoặc xử lý lỗi nghiệp vụ Group Not Found Exception theo phản hồi API thống nhất.
 */

package com.splitdebt.api.exception;

public class GroupNotFoundException extends RuntimeException {
    public GroupNotFoundException(String message) {
        super(message);
    }
}
