package com.splitdebt.api.service;

import com.splitdebt.api.config.SupabaseProperties;
import com.splitdebt.api.service.impl.SupabaseStorageServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.client.RestClient;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class SupabaseStorageServiceTest {

    private SupabaseProperties properties;
    private SupabaseStorageService storageService;

    @Mock
    private RestClient.Builder restClientBuilder;

    @BeforeEach
    void setUp() {
        properties = new SupabaseProperties();
        properties.setUrl("https://zvgpxmzznstotmqfwjet.supabase.co");
        properties.setBucket("Avatar");
        properties.setKey("dummy-key");

        storageService = new SupabaseStorageServiceImpl(properties, restClientBuilder);
    }

    @Test
    void normalizeAvatarPath_withJpeg_returnsCorrectPathAndExtension() {
        String path = storageService.normalizeAvatarPath(123L, "image/jpeg");

        assertTrue(path.startsWith("users/123/avatar_"));
        assertTrue(path.endsWith(".jpg"));
    }

    @Test
    void normalizeAvatarPath_withPng_returnsCorrectExtension() {
        String path = storageService.normalizeAvatarPath(456L, "image/png");

        assertTrue(path.startsWith("users/456/avatar_"));
        assertTrue(path.endsWith(".png"));
    }

    @Test
    void normalizeAvatarPath_withWebp_returnsCorrectExtension() {
        String path = storageService.normalizeAvatarPath(789L, "image/webp");

        assertTrue(path.startsWith("users/789/avatar_"));
        assertTrue(path.endsWith(".webp"));
    }

    @Test
    void normalizeAvatarPath_withInvalidContentType_throwsException() {
        Exception ex = assertThrows(IllegalArgumentException.class, () ->
                storageService.normalizeAvatarPath(123L, "application/pdf"));

        assertTrue(ex.getMessage().contains("Chỉ chấp nhận ảnh JPG, PNG hoặc WEBP"));
    }

    @Test
    void uploadAvatar_whenFileEmpty_throwsException() {
        MockMultipartFile emptyFile = new MockMultipartFile(
                "file", "empty.jpg", "image/jpeg", new byte[0]
        );

        Exception ex = assertThrows(IllegalArgumentException.class, () ->
                storageService.uploadAvatar(123L, emptyFile));

        assertEquals("File ảnh không được để trống", ex.getMessage());
    }

    @Test
    void uploadAvatar_whenFileTooLarge_throwsException() {
        byte[] largeBytes = new byte[6 * 1024 * 1024]; // 6MB
        MockMultipartFile largeFile = new MockMultipartFile(
                "file", "large.jpg", "image/jpeg", largeBytes
        );

        Exception ex = assertThrows(IllegalArgumentException.class, () ->
                storageService.uploadAvatar(123L, largeFile));

        assertTrue(ex.getMessage().contains("5MB"));
    }

    @Test
    void uploadAvatar_whenKeyMissing_throwsIllegalStateException() {
        properties.setKey(""); // Empty key
        MockMultipartFile validFile = new MockMultipartFile(
                "file", "test.jpg", "image/jpeg", new byte[]{1, 2, 3}
        );

        Exception ex = assertThrows(IllegalStateException.class, () ->
                storageService.uploadAvatar(123L, validFile));

        assertTrue(ex.getMessage().contains("SUPABASE_KEY"));
    }
}
