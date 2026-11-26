/**
 * Trách nhiệm file: Biểu diễn hoặc xử lý lỗi nghiệp vụ Member Already Exists Exception theo phản hồi API thống nhất.
 */

package com.splitdebt.api.exception;

public class MemberAlreadyExistsException extends RuntimeException {
    public MemberAlreadyExistsException(String message) {
        super(message);
    }
}
