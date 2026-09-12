package com.splitdebt.api.ledger;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class PasswordResetService {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String GENERIC_MESSAGE =
            "Nếu email tồn tại trong SplitDebt, mã xác minh đã được gửi. Mã có hiệu lực trong thời gian ngắn.";

    private final JdbcTemplate db;
    private final PasswordService passwords;
    private final int ttlMinutes;
    private final boolean devReturnCode;
    private final String mailHost;
    private final int mailPort;
    private final String mailUsername;
    private final String mailPassword;
    private final String mailFrom;
    private final boolean mailStartTls;

    public PasswordResetService(
            JdbcTemplate db,
            PasswordService passwords,
            @Value("${splitdebt.password-reset.ttl-minutes:10}") int ttlMinutes,
            @Value("${splitdebt.password-reset.dev-return-code:false}") boolean devReturnCode,
            @Value("${splitdebt.mail.host:}") String mailHost,
            @Value("${splitdebt.mail.port:587}") int mailPort,
            @Value("${splitdebt.mail.username:}") String mailUsername,
            @Value("${splitdebt.mail.password:}") String mailPassword,
            @Value("${splitdebt.mail.from:no-reply@splitdebt.local}") String mailFrom,
            @Value("${splitdebt.mail.starttls:true}") boolean mailStartTls) {
        this.db = db;
        this.passwords = passwords;
        this.ttlMinutes = Math.max(5, Math.min(ttlMinutes, 60));
        this.devReturnCode = devReturnCode;
        this.mailHost = safe(mailHost);
        this.mailPort = mailPort;
        this.mailUsername = safe(mailUsername);
        this.mailPassword = mailPassword == null ? "" : mailPassword;
        this.mailFrom = safe(mailFrom).isBlank() ? "no-reply@splitdebt.local" : safe(mailFrom);
        this.mailStartTls = mailStartTls;
    }

    @Transactional
    public Map<String, Object> request(String rawEmail) {
        String email = normalizeEmail(rawEmail);
        List<Long> ids = db.query("SELECT id FROM users WHERE LOWER(email)=?",
                (r, n) -> r.getLong("id"), email);

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("message", GENERIC_MESSAGE);
        out.put("expiresInMinutes", ttlMinutes);
        if (ids.isEmpty()) return out;

        long userId = ids.get(0);
        db.update("UPDATE password_reset_tokens SET used_at=CURRENT_TIMESTAMP WHERE user_id=? AND used_at IS NULL", userId);

        String code = String.format(Locale.ROOT, "%06d", RANDOM.nextInt(1_000_000));
        String hash = sha256(code);
        Instant expires = Instant.now().plusSeconds(ttlMinutes * 60L);
        db.update("INSERT INTO password_reset_tokens(user_id,token_hash,expires_at,attempts,created_at) VALUES(?,?,?,?,CURRENT_TIMESTAMP)",
                userId, hash, Timestamp.from(expires), 0);

        sendEmail(email, code);
        if (devReturnCode) {
            out.put("delivery", "DEV");
            out.put("devCode", code);
        }
        return out;
    }

    @Transactional
    public Map<String, Object> reset(String rawEmail, String rawCode, String newPassword) {
        String email = normalizeEmail(rawEmail);
        String code = rawCode == null ? "" : rawCode.trim();
        if (!code.matches("\\d{6}")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã xác minh phải gồm 6 chữ số.");
        }
        if (newPassword == null || newPassword.length() < 8 || newPassword.length() > 100) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mật khẩu mới phải có từ 8 đến 100 ký tự.");
        }

        List<Long> users = db.query("SELECT id FROM users WHERE LOWER(email)=?",
                (r, n) -> r.getLong("id"), email);
        if (users.isEmpty()) invalid();
        long userId = users.get(0);

        List<Map<String, Object>> rows = db.query(
                "SELECT id,token_hash,attempts FROM password_reset_tokens "
                        + "WHERE user_id=? AND used_at IS NULL AND expires_at>CURRENT_TIMESTAMP "
                        + "ORDER BY created_at DESC LIMIT 1",
                (r, n) -> Map.<String, Object>of(
                        "id", r.getLong("id"),
                        "hash", r.getString("token_hash"),
                        "attempts", r.getInt("attempts")), userId);
        if (rows.isEmpty()) invalid();

        Map<String, Object> row = rows.get(0);
        long tokenId = (long) row.get("id");
        int attempts = (int) row.get("attempts");
        if (attempts >= 5 || !MessageDigest.isEqual(
                ((String) row.get("hash")).getBytes(StandardCharsets.UTF_8),
                sha256(code).getBytes(StandardCharsets.UTF_8))) {
            int next = attempts + 1;
            db.update("UPDATE password_reset_tokens SET attempts=?, used_at=CASE WHEN ?>=5 THEN CURRENT_TIMESTAMP ELSE used_at END WHERE id=?",
                    next, next, tokenId);
            invalid();
        }

        String newHash = passwords.hash(newPassword);
        int changed = db.update("UPDATE users SET password_hash=?,updated_at=CURRENT_TIMESTAMP WHERE id=?",
                newHash, userId);
        if (changed == 0) invalid();
        db.update("UPDATE password_reset_tokens SET used_at=CURRENT_TIMESTAMP WHERE user_id=? AND used_at IS NULL", userId);
        return Map.of("message", "Đổi mật khẩu thành công. Bạn có thể đăng nhập bằng mật khẩu mới.");
    }

    private boolean sendEmail(String to, String code) {
        if (mailHost.isBlank()) return false;
        try {
            JavaMailSenderImpl sender = new JavaMailSenderImpl();
            sender.setHost(mailHost);
            sender.setPort(mailPort);
            if (!mailUsername.isBlank()) sender.setUsername(mailUsername);
            if (!mailPassword.isBlank()) sender.setPassword(mailPassword);
            Properties props = sender.getJavaMailProperties();
            props.put("mail.smtp.auth", Boolean.toString(!mailUsername.isBlank()));
            props.put("mail.smtp.starttls.enable", Boolean.toString(mailStartTls));

            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(mailFrom);
            message.setTo(to);
            message.setSubject("SplitDebt - Mã đặt lại mật khẩu");
            message.setText("Mã xác minh của bạn là: " + code + "\n\n"
                    + "Mã có hiệu lực trong " + ttlMinutes + " phút. "
                    + "Nếu bạn không yêu cầu đổi mật khẩu, hãy bỏ qua email này.");
            sender.send(message);
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static String normalizeEmail(String value) {
        String email = value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
        if (!email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Email không hợp lệ.");
        }
        return email;
    }

    private static String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private static String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] bytes = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder out = new StringBuilder(bytes.length * 2);
            for (byte b : bytes) out.append(String.format(Locale.ROOT, "%02x", b));
            return out.toString();
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }

    private static void invalid() {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã xác minh không hợp lệ hoặc đã hết hạn.");
    }
}
