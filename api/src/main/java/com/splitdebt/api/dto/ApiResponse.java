package com.splitdebt.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data 
@Builder 
@NoArgsConstructor 
@AllArgsConstructor 
public class ApiResponse<T> {
    private int status; // HTTP status code nhu 200, 201, 400, 404...
    private String message;
    private T data;

    public boolean isSuccess() { return status >= 200 && status < 300; }
    public static <T> ApiResponse<T> ok(T data) { return success(data, "Thành công"); }
    public static <T> ApiResponse<T> ok(String message, T data) { return success(data, message); }

    // ham tien ich
    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(200, message, data);
    }

    public static <T> ApiResponse<T> error(int status, String message) {
        return new ApiResponse<T>(status, message, null);
    }
}
