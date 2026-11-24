package com.splitdebt.api.service;

import com.splitdebt.api.dto.UserDto;
import com.splitdebt.api.dto.request.UpdateProfileRequest;
import com.splitdebt.api.dto.response.UserActivityLogDto;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.UserActivityLog;
import com.splitdebt.api.repository.UserActivityLogRepository;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.impl.UserServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserActivityLogRepository userActivityLogRepository;

    @InjectMocks
    private UserServiceImpl userService;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        sampleUser = User.builder()
                .id(1L)
                .fullName("Nguyen Van A")
                .email("a@example.com")
                .phone("0901234567")
                .avatarUrl("https://example.com/old_avatar.png")
                .build();
    }

    @Test
    void getCurrentUser_success() {
        when(userRepository.findByEmail("a@example.com")).thenReturn(Optional.of(sampleUser));

        UserDto dto = userService.getCurrentUser("a@example.com");

        assertNotNull(dto);
        assertEquals("Nguyen Van A", dto.getFullName());
        assertEquals("a@example.com", dto.getEmail());
    }

    @Test
    void updateProfile_whenNameAndPhoneChanged_logsActivityAndSavesUser() {
        when(userRepository.findByEmail("a@example.com")).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UpdateProfileRequest request = UpdateProfileRequest.builder()
                .fullName("Nguyen Van B")
                .phone("0988888888")
                .build();

        UserDto updated = userService.updateProfile("a@example.com", request);

        assertEquals("Nguyen Van B", updated.getFullName());
        assertEquals("0988888888", updated.getPhone());
        verify(userRepository).save(sampleUser);

        // Verify that 2 logs were saved: one for name, one for phone
        verify(userActivityLogRepository, times(2)).save(any(UserActivityLog.class));
    }

    @Test
    void updateProfile_whenNoChange_doesNotSaveLog() {
        when(userRepository.findByEmail("a@example.com")).thenReturn(Optional.of(sampleUser));

        UpdateProfileRequest request = UpdateProfileRequest.builder()
                .fullName("Nguyen Van A")
                .phone("0901234567")
                .build();

        UserDto updated = userService.updateProfile("a@example.com", request);

        assertEquals("Nguyen Van A", updated.getFullName());
        verify(userRepository, never()).save(any());
        verify(userActivityLogRepository, never()).save(any());
    }

    @Test
    void getUserLogs_returnsMappedLogs() {
        when(userRepository.findByEmail("a@example.com")).thenReturn(Optional.of(sampleUser));

        UserActivityLog log1 = UserActivityLog.builder()
                .id(101L)
                .userId(1L)
                .action("UPDATE_PROFILE")
                .description("Đổi họ và tên thành \"Nguyen Van B\"")
                .oldValue("Nguyen Van A")
                .newValue("Nguyen Van B")
                .createdAt(LocalDateTime.now())
                .build();

        when(userActivityLogRepository.findByUserIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(log1));

        List<UserActivityLogDto> logs = userService.getUserLogs("a@example.com");

        assertEquals(1, logs.size());
        assertEquals("UPDATE_PROFILE", logs.get(0).getAction());
        assertEquals("Đổi họ và tên thành \"Nguyen Van B\"", logs.get(0).getDescription());
    }
}

