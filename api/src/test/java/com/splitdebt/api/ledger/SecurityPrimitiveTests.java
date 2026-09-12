package com.splitdebt.api.ledger;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class SecurityPrimitiveTests {
    @Test
    void passwordsAreSaltedAndCanBeVerified() {
        PasswordService service = new PasswordService();
        String first = service.hash("correct horse battery staple");
        String second = service.hash("correct horse battery staple");

        assertTrue(first.startsWith("pbkdf2_sha256$"));
        assertNotEquals(first, second, "A random salt should produce different hashes.");
        assertTrue(service.matches("correct horse battery staple", first));
        assertFalse(service.matches("wrong", first));
        assertFalse(service.matches("anything", "plain-text"));
    }

    @Test
    void jwtCanBeIssuedVerifiedAndTamperingIsRejected() {
        JwtService service = new JwtService(new ObjectMapper(), "unit-test-secret-value", 1);
        String token = service.issue(42L, "duy@example.com", "Duy");
        JwtService.Claims claims = service.verify(token);

        assertNotNull(claims);
        assertEquals(42L, claims.userId());
        assertEquals("duy@example.com", claims.email());
        assertEquals("Duy", claims.name());
        assertTrue(claims.expiresAt() > java.time.Instant.now().getEpochSecond());

        char replacement = token.charAt(token.length() - 1) == 'a' ? 'b' : 'a';
        String tampered = token.substring(0, token.length() - 1) + replacement;
        assertNull(service.verify(tampered));
        assertNull(service.verify("not-a-jwt"));
        assertNull(service.verify(""));
    }
}
