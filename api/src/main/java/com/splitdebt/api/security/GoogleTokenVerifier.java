/**
 * Trách nhiệm file: Xác minh chữ ký, issuer, thời hạn và audience của Google ID token.
 */

package com.splitdebt.api.security;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;

@Component
public class GoogleTokenVerifier {

    private final String webClientId;
    private final GoogleIdTokenVerifier verifier;

    public GoogleTokenVerifier(
            @Value("${app.google.web-client-id:}") String webClientId) {
        this.webClientId = webClientId == null ? "" : webClientId.trim();
        this.verifier = this.webClientId.isEmpty()
                ? null
                : new GoogleIdTokenVerifier.Builder(
                        new NetHttpTransport(),
                        GsonFactory.getDefaultInstance())
                        .setAudience(Collections.singletonList(this.webClientId))
                        .build();
    }

    public GoogleIdentity verify(String rawIdToken) {
        if (rawIdToken == null || rawIdToken.isBlank()) {
            throw new IllegalArgumentException("Google ID token không được để trống");
        }
        if (webClientId.isEmpty() || verifier == null) {
            throw new IllegalStateException(
                    "Google OAuth chưa được cấu hình trên máy chủ");
        }

        try {
            GoogleIdToken token = verifier.verify(rawIdToken.trim());
            if (token == null) {
                throw new IllegalArgumentException("Google ID token không hợp lệ hoặc đã hết hạn");
            }

            GoogleIdToken.Payload payload = token.getPayload();
            if (!Boolean.TRUE.equals(payload.getEmailVerified())) {
                throw new IllegalArgumentException("Email Google chưa được xác minh");
            }

            String email = payload.getEmail();
            if (email == null || email.isBlank()) {
                throw new IllegalArgumentException("Google ID token không chứa email");
            }

            String subject = payload.getSubject();
            if (subject == null || subject.isBlank()) {
                throw new IllegalArgumentException("Google ID token không chứa subject");
            }

            return new GoogleIdentity(
                    subject,
                    email,
                    stringClaim(payload, "name"),
                    stringClaim(payload, "picture"),
                    payload.getHostedDomain());
        } catch (GeneralSecurityException | IOException ex) {
            throw new IllegalArgumentException("Không thể xác minh Google ID token", ex);
        }
    }

    private String stringClaim(GoogleIdToken.Payload payload, String claim) {
        Object value = payload.get(claim);
        return value == null ? null : value.toString().trim();
    }

    /** Dữ liệu danh tính duy nhất được phép đi tiếp sau khi token đã xác minh. */
    public record GoogleIdentity(
            String subject,
            String email,
            String fullName,
            String avatarUrl,
            String hostedDomain) {
    }
}
