package com.splitdebt.api.ledger;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import java.util.Collections;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class GoogleIdentityService {
    public record GoogleIdentity(String subject, String email, String name, String avatarUrl) {}

    private final String clientId;

    public GoogleIdentityService(@Value("${splitdebt.google-client-id:}") String clientId) {
        this.clientId = clientId == null ? "" : clientId.trim();
    }

    public GoogleIdentity verify(String rawIdToken) {
        if (clientId.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Google Sign-In chưa được cấu hình trên Backend.");
        }
        if (rawIdToken == null || rawIdToken.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu Google ID token.");
        }

        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                    new NetHttpTransport(),
                    GsonFactory.getDefaultInstance())
                    .setAudience(Collections.singletonList(clientId))
                    .build();

            GoogleIdToken token = verifier.verify(rawIdToken.trim());
            if (token == null) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Phiên đăng nhập Google không hợp lệ.");
            }

            GoogleIdToken.Payload payload = token.getPayload();
            if (!Boolean.TRUE.equals(payload.getEmailVerified())) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email Google chưa được xác minh.");
            }

            String subject = payload.getSubject();
            String email = payload.getEmail();
            String name = payload.get("name") == null ? null : payload.get("name").toString();
            String avatar = payload.get("picture") == null ? null : payload.get("picture").toString();
            if (subject == null || subject.isBlank() || email == null || email.isBlank()) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Google không trả về đủ thông tin tài khoản.");
            }
            if (name == null || name.isBlank()) name = email.split("@", 2)[0];
            return new GoogleIdentity(subject, email, name, avatar);
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Không thể xác minh tài khoản Google lúc này. Vui lòng thử lại.");
        }
    }
}
