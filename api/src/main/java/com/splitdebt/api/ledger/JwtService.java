package com.splitdebt.api.ledger;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
    public record Claims(long userId, String email, String name, long expiresAt) {}

    private final ObjectMapper mapper;
    private final byte[] secret;
    private final long ttlSeconds;

    public JwtService(ObjectMapper mapper,
                      @Value("${splitdebt.jwt-secret}") String secret,
                      @Value("${splitdebt.jwt-ttl-hours:168}") long ttlHours) {
        this.mapper = mapper;
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
        this.ttlSeconds = Math.max(1, ttlHours) * 3600L;
    }

    public String issue(long userId, String email, String name) {
        long now = Instant.now().getEpochSecond();
        Map<String, Object> header = Map.of("alg", "HS256", "typ", "JWT");
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("sub", Long.toString(userId));
        payload.put("email", email);
        payload.put("name", name);
        payload.put("iat", now);
        payload.put("exp", now + ttlSeconds);
        try {
            String head = encode(mapper.writeValueAsBytes(header));
            String body = encode(mapper.writeValueAsBytes(payload));
            String unsigned = head + "." + body;
            return unsigned + "." + encode(sign(unsigned));
        } catch (Exception e) {
            throw new IllegalStateException("Unable to create a login token.", e);
        }
    }

    public Claims verify(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) return null;
            String unsigned = parts[0] + "." + parts[1];
            byte[] expected = sign(unsigned);
            byte[] actual = Base64.getUrlDecoder().decode(parts[2]);
            if (!java.security.MessageDigest.isEqual(expected, actual)) return null;
            Map<String, Object> payload = mapper.readValue(Base64.getUrlDecoder().decode(parts[1]), new TypeReference<>() {});
            long exp = ((Number) payload.getOrDefault("exp", 0)).longValue();
            if (exp <= Instant.now().getEpochSecond()) return null;
            long userId = Long.parseLong(String.valueOf(payload.get("sub")));
            String email = String.valueOf(payload.getOrDefault("email", ""));
            String name = String.valueOf(payload.getOrDefault("name", ""));
            if (email.isBlank()) return null;
            return new Claims(userId, email, name, exp);
        } catch (Exception ignored) {
            return null;
        }
    }

    private byte[] sign(String value) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret, "HmacSHA256"));
        return mac.doFinal(value.getBytes(StandardCharsets.UTF_8));
    }

    private static String encode(byte[] value) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(value);
    }
}
