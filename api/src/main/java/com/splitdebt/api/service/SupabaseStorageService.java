/**
 * Trách nhiệm file: Định nghĩa interface dịch vụ lưu trữ Supabase Storage (upload avatar, sinh URL).
 */

package com.splitdebt.api.service;

import org.springframework.web.multipart.MultipartFile;

public interface SupabaseStorageService {

    /**
     * Upload ảnh đại diện của người dùng lên Supabase Storage với tên file được chuẩn hóa.
     *
     * @param userId ID của người dùng sở hữu ảnh
     * @param file File ảnh tải lên
     * @return Public URL có thể truy cập ảnh trực tiếp từ internet
     */
    String uploadAvatar(Long userId, MultipartFile file);

    /**
     * Chuẩn hóa tên đường dẫn file ảnh dựa theo userId, timestamp và định dạng.
     * Định dạng chuẩn: users/{userId}/avatar_{timestamp}_{shortUuid}.{ext}
     *
     * @param userId ID người dùng
     * @param originalContentType Content-Type của file (image/jpeg, image/png, image/webp)
     * @return Đường dẫn file đã được chuẩn hóa
     */
    String normalizeAvatarPath(Long userId, String originalContentType);
}
