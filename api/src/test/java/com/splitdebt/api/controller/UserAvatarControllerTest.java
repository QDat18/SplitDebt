package com.splitdebt.api.controller;

import com.splitdebt.api.dto.UserDto;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.SupabaseStorageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserAvatarControllerTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private SupabaseStorageService supabaseStorageService;

    @Mock
    private com.splitdebt.api.service.UserService userService;

    @Mock
    private SecurityContext securityContext;

    @Mock
    private Authentication authentication;

    @InjectMocks
    private UserController userController;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.setContext(securityContext);
    }

    @Test
    void uploadAvatar_success_updatesUserAndReturnsUserDto() {
        String email = "test@example.com";
        when(securityContext.getAuthentication()).thenReturn(authentication);
        when(authentication.getName()).thenReturn(email);

        User mockUser = new User();
        mockUser.setId(10L);
        mockUser.setFullName("Test User");
        mockUser.setEmail(email);

        when(userRepository.findByEmail(email)).thenReturn(Optional.of(mockUser));
        when(supabaseStorageService.uploadAvatar(eq(10L), any())).thenReturn("https://supabase.co/storage/v1/object/public/Avatar/users/10/avatar.jpg");

        MockMultipartFile file = new MockMultipartFile(
                "file", "avatar.jpg", "image/jpeg", new byte[]{1, 2, 3}
        );

        ResponseEntity<UserDto> response = userController.uploadAvatar(file);

        assertEquals(200, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("https://supabase.co/storage/v1/object/public/Avatar/users/10/avatar.jpg", response.getBody().getAvatarUrl());
        assertEquals("https://supabase.co/storage/v1/object/public/Avatar/users/10/avatar.jpg", mockUser.getAvatarUrl());

        verify(userRepository).save(mockUser);
    }
}
