# Kế hoạch Triển khai: Đổi ảnh đại diện (Avatar) lưu trữ trên Supabase Storage

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cho phép người dùng đổi ảnh đại diện (Avatar), ảnh được upload lên Supabase Storage bucket `Avatar` với tên file được chuẩn hóa, lưu URL vào CSDL và cập nhật hiển thị đồng bộ trên ứng dụng di động.

**Architecture:**
- **Backend (Spring Boot 3.3):**
  - Sử dụng `RestClient` tích hợp sẵn trong Spring Boot để giao tiếp với Supabase Storage REST API. Không thay đổi `pom.xml`.
  - Cấu hình qua `application.yaml` (`app.supabase.url`, `key`, `bucket`).
  - Dịch vụ `SupabaseStorageService`: Chuẩn hóa tên file theo `users/{userId}/avatar_{timestamp}_{shortUuid}.{ext}`, kiểm tra MIME type (`image/jpeg`, `image/png`, `image/webp`) và kích thước (tối đa 5MB), upload và sinh Public URL.
  - Endpoint `POST /api/users/me/avatar` (multipart/form-data): Nhận file, upload lên Supabase, cập nhật `user.avatar_url`, trả về `UserDto`.
- **Frontend (Flutter):**
  - Thêm `image_picker: ^1.1.2` vào `frontend/pubspec.yaml`.
  - Thêm tính năng chọn ảnh (Camera / Thư viện) tại `personal_info_screen.dart` và `profile_screen.dart`.
  - Hiển thị `CircleAvatar` dùng `NetworkImage` khi có `avatarUrl`, có fallback chữ cái đầu khi chưa có ảnh hoặc lỗi tải.

**Tech Stack:** Java 17, Spring Boot 3.3 (`RestClient`), Flutter, Riverpod, `image_picker`, Supabase Storage REST API.

---

## Danh sách Task

### Task 1: Backend - Supabase Storage Configuration & Service
- [ ] File: `api/src/main/resources/application.yaml`
  - Thêm cấu hình `app.supabase`: `url`, `key`, `bucket`.
- [ ] File: `api/src/main/java/com/splitdebt/api/config/SupabaseProperties.java`
  - `@ConfigurationProperties(prefix = "app.supabase")` chứa `url`, `key`, `bucket`.
- [ ] File: `api/src/main/java/com/splitdebt/api/service/SupabaseStorageService.java`
  - Interface định nghĩa `String uploadAvatar(Long userId, MultipartFile file)`.
- [ ] File: `api/src/main/java/com/splitdebt/api/service/impl/SupabaseStorageServiceImpl.java`
  - Kiểm tra file hợp lệ (MIME type, size <= 5MB).
  - Chuẩn hóa tên file: `users/{userId}/avatar_{timestamp}_{shortUuid}.{ext}`.
  - Gọi REST API Supabase: `POST /storage/v1/object/{bucket}/{filePath}` với headers `Authorization: Bearer {key}`, `apiKey: {key}`, `Content-Type`.
  - Trả về URL công khai: `{url}/storage/v1/object/public/{bucket}/{filePath}`.
- [ ] File: `api/src/test/java/com/splitdebt/api/service/SupabaseStorageServiceTest.java`
  - Unit test kiểm tra chuẩn hóa tên file, validation MIME/size, và gọi API upload.

### Task 2: Backend - API Endpoint `POST /api/users/me/avatar`
- [ ] File: `api/src/main/java/com/splitdebt/api/controller/UserController.java`
  - Thêm method `uploadAvatar(@RequestParam("file") MultipartFile file)`:
    - Lấy thông tin user hiện tại qua `authentication.getName()`.
    - Gọi `supabaseStorageService.uploadAvatar(user.getId(), file)`.
    - Lưu `user.setAvatarUrl(newUrl)` và `userRepository.save(user)`.
    - Trả về `ResponseEntity.ok(userDto)`.
- [ ] File: `api/src/test/java/com/splitdebt/api/controller/UserAvatarControllerTest.java`
  - Test xác thực endpoint `POST /api/users/me/avatar` với mock `SupabaseStorageService`.

### Task 3: Frontend - `image_picker` & API Upload Service
- [ ] File: `frontend/pubspec.yaml`
  - Thêm `image_picker: ^1.1.2`.
- [ ] File: `frontend/lib/data/repositories/user_repository.dart`
  - Tạo service hoặc hàm upload avatar gọi `dioClient.post('/users/me/avatar', data: FormData.fromMap({'file': MultipartFile.fromFile(...)})`.

### Task 4: Frontend - UI Đổi Avatar (ProfileScreen & PersonalInfoScreen)
- [ ] File: `frontend/lib/features/profile/personal_info_screen.dart`
  - Cập nhật hiển thị `CircleAvatar`: ưu tiên `NetworkImage` nếu có `avatarUrl`, hiển thị icon camera nhỏ ở góc dưới avatar.
  - Khi bấm vào avatar: mở modal chọn "Chụp ảnh mới" hoặc "Chọn từ thư viện ảnh".
  - Hiển thị spinner khi đang tải ảnh lên và SnackBar thông báo kết quả.
- [ ] File: `frontend/lib/features/profile/profile_screen.dart`
  - Tải và lưu `_avatarUrl` từ `/users/me`.
  - Hiển thị `CircleAvatar` có `NetworkImage`.
- [ ] File: `frontend/test/profile_screen_test.dart`
  - Bổ sung test kiểm tra hiển thị avatar khi có URL và khi không có URL.

### Task 5: Kiểm thử toàn diện & Cập nhật Tiến độ
- [ ] Chạy test Backend: `cd api; .\mvnw.cmd test`
- [ ] Chạy test Frontend: `cd frontend; flutter analyze --no-fatal-infos; flutter test`
- [ ] Cập nhật `docs/PROGRESS.md` (giữ <= 30 dòng).

