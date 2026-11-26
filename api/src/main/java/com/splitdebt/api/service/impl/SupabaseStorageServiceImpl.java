/**
 * Trách nhiệm file: Hiện thực hoá dịch vụ Supabase Storage Service: validate file, chuẩn hóa tên file và gọi REST API.
 */

package com.splitdebt.api.service.impl;

import com.splitdebt.api.config.SupabaseProperties;
import com.splitdebt.api.service.SupabaseStorageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class SupabaseStorageServiceImpl implements SupabaseStorageService {

    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB

    private final SupabaseProperties properties;
    private final RestClient.Builder restClientBuilder;

    @Override
    public String uploadAvatar(Long userId, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File ảnh không được để trống");
        }

        if (file.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("Kích thước file ảnh không được vượt quá 5MB");
        }

        String contentType = file.getContentType();
        String filePath = normalizeAvatarPath(userId, contentType);

        String supabaseKey = properties.getKey();
        if (supabaseKey == null || supabaseKey.isBlank()) {
            log.error("SUPABASE_KEY chưa được cấu hình trong hệ thống");
            throw new IllegalStateException("Hệ thống lưu trữ ảnh chưa được cấu hình khóa truy cập (SUPABASE_KEY)");
        }

        String uploadUri = properties.getUrl() + "/storage/v1/object/" + properties.getBucket() + "/" + filePath;

        try {
            RestClient restClient = restClientBuilder.build();
            restClient.post()
                    .uri(uploadUri)
                    .header("Authorization", "Bearer " + supabaseKey)
                    .header("apiKey", supabaseKey)
                    .header("x-upsert", "true")
                    .contentType(MediaType.parseMediaType(contentType != null ? contentType : "image/jpeg"))
                    .body(file.getBytes())
                    .retrieve()
                    .toBodilessEntity();

            String publicUrl = properties.getUrl() + "/storage/v1/object/public/" + properties.getBucket() + "/" + filePath;
            log.info("Đã upload avatar thành công cho user {}: {}", userId, publicUrl);
            return publicUrl;
        } catch (IOException e) {
            log.error("Lỗi đọc dữ liệu file ảnh: {}", e.getMessage(), e);
            throw new RuntimeException("Không thể đọc dữ liệu file ảnh", e);
        } catch (Exception e) {
            log.error("Lỗi khi upload ảnh lên Supabase Storage: {}", e.getMessage(), e);
            throw new RuntimeException("Lỗi lưu trữ ảnh trên Supabase: " + e.getMessage(), e);
        }
    }

    @Override
    public String normalizeAvatarPath(Long userId, String originalContentType) {
        if (userId == null) {
            throw new IllegalArgumentException("User ID không được để trống");
        }

        String ext;
        if (originalContentType != null) {
            String lower = originalContentType.toLowerCase().trim();
            if (lower.contains("png")) {
                ext = "png";
            } else if (lower.contains("webp")) {
                ext = "webp";
            } else if (lower.contains("jpeg") || lower.contains("jpg")) {
                ext = "jpg";
            } else {
                throw new IllegalArgumentException("Định dạng file không hợp lệ. Chỉ chấp nhận ảnh JPG, PNG hoặc WEBP");
            }
        } else {
            ext = "jpg";
        }

        long timestamp = System.currentTimeMillis();
        String shortUuid = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
        return String.format("users/%d/avatar_%d_%s.%s", userId, timestamp, shortUuid, ext);
    }

    @Override
    public void deleteObject(String publicUrl) {
        if (publicUrl == null || publicUrl.isBlank()) {
            return;
        }
        String supabaseKey = properties.getKey();
        if (supabaseKey == null || supabaseKey.isBlank()) {
            log.warn("SUPABASE_KEY chưa được cấu hình, bỏ qua xoá file {}", publicUrl);
            return;
        }
        String marker = "/storage/v1/object/public/" + properties.getBucket() + "/";
        int idx = publicUrl.indexOf(marker);
        if (idx < 0) {
            log.warn("URL không khớp định dạng Supabase bucket {}: {}", properties.getBucket(), publicUrl);
            return;
        }
        String filePath = publicUrl.substring(idx + marker.length());
        String deleteUri = properties.getUrl() + "/storage/v1/object/" + properties.getBucket() + "/" + filePath;
        try {
            restClientBuilder.build()
                    .delete()
                    .uri(deleteUri)
                    .header("Authorization", "Bearer " + supabaseKey)
                    .header("apiKey", supabaseKey)
                    .retrieve()
                    .toBodilessEntity();
        } catch (Exception e) {
            log.warn("Không thể xoá file trên Supabase {}: {}", deleteUri, e.getMessage());
        }
    }
}
