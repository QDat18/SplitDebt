/**
 * Trách nhiệm file: Ngoại lệ khi mật khẩu xác nhận không đúng (401).
 */

package com.splitdebt.api.exception;

public class InvalidPasswordException extends RuntimeException {
    public InvalidPasswordException(String message) {
        super(message);
    }
}

