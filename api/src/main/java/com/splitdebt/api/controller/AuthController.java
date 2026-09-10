package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.AuthResponse;
import com.splitdebt.api.dto.LoginRequest;
import com.splitdebt.api.dto.RegisterRequest;
import com.splitdebt.api.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@RequestBody RegisterRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.register(request), "Dang ky thanh cong"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@RequestBody LoginRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.login(request), "Dang nhap thanh cong"));
    }
}
