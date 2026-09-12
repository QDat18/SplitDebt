package com.splitdebt.api.ledger;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.Map;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    public record RegisterInput(
            @NotBlank @Size(max = 100) String fullName,
            @NotBlank @Email @Size(max = 255) String email,
            @Size(max = 20) String phone,
            @NotBlank @Size(min = 8, max = 100) String password,
            boolean acceptedTerms) {}

    public record LoginInput(
            @NotBlank @Email @Size(max = 255) String email,
            @NotBlank @Size(max = 100) String password) {}

    public record GoogleInput(@NotBlank String idToken) {}
    public record ForgotPasswordInput(@NotBlank @Email @Size(max = 255) String email) {}
    public record ResetPasswordInput(
            @NotBlank @Email @Size(max = 255) String email,
            @NotBlank @Size(min = 6, max = 6) String code,
            @NotBlank @Size(min = 8, max = 100) String newPassword) {}

    private final LedgerService service;
    private final GoogleIdentityService googleIdentity;
    private final PasswordResetService passwordReset;

    public AuthController(
            LedgerService service,
            GoogleIdentityService googleIdentity,
            PasswordResetService passwordReset) {
        this.service = service;
        this.googleIdentity = googleIdentity;
        this.passwordReset = passwordReset;
    }

    @PostMapping("/register")
    public Object register(@Valid @RequestBody RegisterInput input) {
        if (!input.acceptedTerms()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "You must agree to the Terms of Service and Privacy Policy.");
        }
        return service.register(input.fullName(), input.email(), input.phone(), input.password());
    }

    @PostMapping("/login")
    public Object login(@Valid @RequestBody LoginInput input) {
        return service.login(input.email(), input.password());
    }

    @PostMapping("/google")
    public Object google(@Valid @RequestBody GoogleInput input) {
        return service.googleLogin(googleIdentity.verify(input.idToken()));
    }

    @PostMapping("/forgot-password")
    public Map<String, Object> forgotPassword(@Valid @RequestBody ForgotPasswordInput input) {
        return passwordReset.request(input.email());
    }

    @PostMapping("/reset-password")
    public Map<String, Object> resetPassword(@Valid @RequestBody ResetPasswordInput input) {
        return passwordReset.reset(input.email(), input.code(), input.newPassword());
    }
}
