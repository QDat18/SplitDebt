/**
 * Trách nhiệm file: Định nghĩa hoặc thực thi nghiệp vụ Auth Service dùng chung cho các controller backend.
 */

package com.splitdebt.api.service;

import com.splitdebt.api.dto.AuthResponse;
import com.splitdebt.api.dto.GoogleLoginRequest;
import com.splitdebt.api.dto.LoginRequest;
import com.splitdebt.api.dto.RegisterRequest;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.security.JwtUtils;
import com.splitdebt.api.security.GoogleTokenVerifier;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$",
            Pattern.CASE_INSENSITIVE);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;
    private final GoogleTokenVerifier googleTokenVerifier;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        validateRegistration(request);
        String email = normalizeEmail(request.getEmail());
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email is already in use");
        }

        User user = new User();
        user.setFullName(request.getFullName().trim());
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        
        userRepository.save(user);

        String token = jwtUtils.generateJwtToken(user.getEmail());
        return new AuthResponse(token);
    }

    public AuthResponse login(LoginRequest request) {
        if (request == null || request.getPassword() == null || request.getPassword().isEmpty()) {
            throw new IllegalArgumentException("Invalid email or password");
        }
        String email = normalizeEmail(request.getEmail());
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        String token = jwtUtils.generateJwtToken(user.getEmail());
        return new AuthResponse(token);
    }

    /**
     * Chỉ dùng email/tên/avatar lấy từ token đã được backend xác minh.
     * Tài khoản Google mới nhận mật khẩu ngẫu nhiên không thể đăng nhập trực tiếp.
     */
    @Transactional
    public AuthResponse googleLogin(GoogleLoginRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("Dữ liệu đăng nhập Google không được để trống");
        }

        GoogleTokenVerifier.GoogleIdentity identity = googleTokenVerifier.verify(
                request.getIdToken());
        String email = normalizeEmail(identity.email());

        User user = userRepository.findByGoogleSubject(identity.subject()).orElseGet(() -> {
            User existingUser = userRepository.findByEmail(email).orElse(null);
            if (existingUser != null) {
                if (existingUser.getGoogleSubject() != null
                        && !existingUser.getGoogleSubject().equals(identity.subject())) {
                    throw new IllegalArgumentException(
                            "Tài khoản Google không khớp với tài khoản đã liên kết");
                }
                if (!isGoogleAuthoritativeForEmail(email, identity.hostedDomain())) {
                    throw new IllegalArgumentException(
                            "Email đã tồn tại; hãy đăng nhập bằng mật khẩu để liên kết tài khoản");
                }
                existingUser.setGoogleSubject(identity.subject());
                return userRepository.save(existingUser);
            }

            User newUser = new User();
            newUser.setEmail(email);
            newUser.setGoogleSubject(identity.subject());
            newUser.setFullName(normalizeGoogleName(identity.fullName(), email));
            newUser.setAvatarUrl(emptyToNull(identity.avatarUrl()));
            newUser.setPasswordHash(passwordEncoder.encode(UUID.randomUUID().toString()));
            return userRepository.save(newUser);
        });

        String token = jwtUtils.generateJwtToken(user.getEmail());
        return new AuthResponse(token);
    }

    /** Chỉ tự động liên kết khi Google quản lý địa chỉ Gmail hoặc Workspace. */
    private boolean isGoogleAuthoritativeForEmail(String email, String hostedDomain) {
        return email.endsWith("@gmail.com")
                || (hostedDomain != null && !hostedDomain.isBlank());
    }

    private void validateRegistration(RegisterRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("Dữ liệu đăng ký không được để trống");
        }
        String fullName = request.getFullName() == null ? "" : request.getFullName().trim();
        if (fullName.length() < 2 || fullName.length() > 100) {
            throw new IllegalArgumentException("Họ tên phải có từ 2 đến 100 ký tự");
        }
        normalizeEmail(request.getEmail());
        if (request.getPassword() == null
                || request.getPassword().length() < 8
                || request.getPassword().length() > 72) {
            throw new IllegalArgumentException("Mật khẩu phải có từ 8 đến 72 ký tự");
        }
    }

    private String normalizeEmail(String rawEmail) {
        String email = rawEmail == null ? "" : rawEmail.trim().toLowerCase(Locale.ROOT);
        if (email.length() > 254 || !EMAIL_PATTERN.matcher(email).matches()) {
            throw new IllegalArgumentException("Email không hợp lệ");
        }
        return email;
    }

    private String normalizeGoogleName(String rawName, String email) {
        String name = rawName == null ? "" : rawName.trim();
        if (name.length() < 2) {
            name = email.substring(0, email.indexOf('@'));
        }
        if (name.length() < 2) {
            name = "Google User";
        }
        return name.substring(0, Math.min(name.length(), 100));
    }

    private String emptyToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
