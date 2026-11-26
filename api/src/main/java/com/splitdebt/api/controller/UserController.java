/**
 * Trách nhiệm file: Cung cấp các HTTP endpoint của User Controller, nhận request đã xác thực và chuyển xử lý xuống tầng nghiệp vụ.
 */

package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.UserDto;
import com.splitdebt.api.dto.consent.ConsentStatusDto;
import com.splitdebt.api.dto.consent.ConsentUpdateRequest;
import com.splitdebt.api.dto.privacy.DataExportDto;
import com.splitdebt.api.dto.request.UpdateProfileRequest;
import com.splitdebt.api.dto.response.UserActivityLogDto;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.ConsentService;
import com.splitdebt.api.service.DataExportService;
import com.splitdebt.api.service.SupabaseStorageService;
import com.splitdebt.api.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Tag(name = "6. Users", description = "Các API thông tin người dùng")
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;
    private final SupabaseStorageService supabaseStorageService;
    private final UserService userService;
    private final ConsentService consentService;
    private final DataExportService dataExportService;

    @Operation(summary = "Lấy thông tin người dùng đang đăng nhập", description = "Dựa trên JWT Token để lấy thông tin cá nhân của user.")
    @GetMapping("/me")
    public ResponseEntity<UserDto> getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        return ResponseEntity.ok(userService.getCurrentUser(email));
    }

    @Operation(summary = "Cập nhật đồng ý điều khoản và chính sách", description = "Ghi thêm bản ghi đồng ý mới và trả về trạng thái đồng ý hiện tại.")
    @PostMapping("/me/consents")
    public ResponseEntity<ConsentStatusDto> updateConsents(@RequestBody ConsentUpdateRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
        return ResponseEntity.ok(consentService.update(user.getId(), request));
    }

    @Operation(summary = "Xuất dữ liệu cá nhân", description = "Trả về toàn bộ dữ liệu cá nhân của người dùng đang đăng nhập.")
    @GetMapping("/me/data-export")
    public ResponseEntity<ApiResponse<DataExportDto>> exportMyData() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
        return ResponseEntity.ok(ApiResponse.ok(dataExportService.export(user.getId())));
    }

    @Operation(summary = "Cập nhật thông tin cá nhân", description = "Cập nhật họ tên, số điện thoại và tự động lưu nhật ký hoạt động.")
    @PutMapping("/me")
    public ResponseEntity<UserDto> updateProfile(@Valid @RequestBody UpdateProfileRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        return ResponseEntity.ok(userService.updateProfile(email, request));
    }

    @Operation(summary = "Lấy nhật ký hoạt động của người dùng", description = "Trả về danh sách lịch sử các thay đổi thông tin cá nhân.")
    @GetMapping("/me/logs")
    public ResponseEntity<List<UserActivityLogDto>> getUserLogs() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        return ResponseEntity.ok(userService.getUserLogs(email));
    }

    @Operation(summary = "Cập nhật ảnh đại diện người dùng", description = "Tải file ảnh lên Supabase Storage và cập nhật avatar_url cho user.")
    @PostMapping(value = "/me/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<UserDto> uploadAvatar(@RequestParam("file") MultipartFile file) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        String oldAvatar = user.getAvatarUrl();
        String avatarUrl = supabaseStorageService.uploadAvatar(user.getId(), file);

        user.setAvatarUrl(avatarUrl);
        userRepository.save(user);

        // Ghi nhận vào nhật ký tài khoản
        userService.logActivity(user.getId(), "UPDATE_AVATAR", "Đổi ảnh đại diện mới", oldAvatar, avatarUrl);

        UserDto userDto = UserDto.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .avatarUrl(user.getAvatarUrl())
                .build();

        return ResponseEntity.ok(userDto);
    }
}
