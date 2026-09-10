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

    private final LedgerService service;

    public AuthController(LedgerService service) {
        this.service = service;
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
}
