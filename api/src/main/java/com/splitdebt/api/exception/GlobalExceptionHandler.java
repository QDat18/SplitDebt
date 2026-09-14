package com.splitdebt.api.exception;

import com.splitdebt.api.dto.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ControllerAdvice;  
import org.springframework.http.ResponseEntity;  

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler({GroupNotFoundException.class, UserNotFoundException.class,
            org.springframework.web.servlet.resource.NoResourceFoundException.class})
    public ResponseEntity<ApiResponse<Object>> handleNotFound(Exception ex) {
        return ResponseEntity.status(404).body(ApiResponse.error(404, ex.getMessage()));
    }

    @ExceptionHandler({GroupPermissionException.class, org.springframework.security.access.AccessDeniedException.class})
    public ResponseEntity<ApiResponse<Object>> handlePermission(Exception ex) {
        return ResponseEntity.status(403).body(ApiResponse.error(403, ex.getMessage()));
    }

    @ExceptionHandler(MemberAlreadyExistsException.class)
    public ResponseEntity<ApiResponse<Object>> handleDuplicate(MemberAlreadyExistsException ex) {
        return ResponseEntity.badRequest().body(ApiResponse.error(400, ex.getMessage()));
    }

    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<Object>> handleIntegrity(Exception ex) {
        return ResponseEntity.status(409).body(ApiResponse.error(409,
                "Không thể thực hiện vì dữ liệu đang được sử dụng hoặc đã tồn tại"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Object>> handleException(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(500, "Loi he thong: " + ex.getMessage()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Object>> handleIllegalArgumentException(IllegalArgumentException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, "Loi tham so: " + ex.getMessage()));
    }

    @ExceptionHandler(org.springframework.web.HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Object>> handleMethodNotSupported(org.springframework.web.HttpRequestMethodNotSupportedException ex) {
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED)
                .body(ApiResponse.error(405, "Method khong duoc ho tro: " + ex.getMessage()));
    }

    @ExceptionHandler(org.springframework.web.servlet.NoHandlerFoundException.class)
    public ResponseEntity<ApiResponse<Object>> handleNoHandlerFoundException(org.springframework.web.servlet.NoHandlerFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(404, "Khong tim thay duong dan: " + ex.getRequestURL()));
    }

    @ExceptionHandler(org.springframework.web.bind.MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Object>> handleValidationException(org.springframework.web.bind.MethodArgumentNotValidException ex) {
        String errorMsg = ex.getBindingResult().getFieldErrors().stream()
                .map(err -> err.getField() + " " + err.getDefaultMessage())
                .reduce((a, b) -> a + ", " + b)
                .orElse("Loi xac thuc du lieu");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, "Loi xac thuc: " + errorMsg));
    }
}
