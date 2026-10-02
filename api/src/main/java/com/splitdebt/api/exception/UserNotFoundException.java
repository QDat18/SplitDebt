/**
 * Trách nhiệm file: Biểu diễn hoặc xử lý lỗi nghiệp vụ User Not Found Exception theo phản hồi API thống nhất.
 */

package com.splitdebt.api.exception;

public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String message) {
        super(message);
    }
}
