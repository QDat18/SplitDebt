package com.splitdebt.api.ledger;

import java.util.List;
import java.util.UUID;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

/**
 * Maps the supplied database's UUID identity model (users/groups/group_members)
 * to the BIGINT identifiers used by the financial ledger tables and the Flutter API.
 */
final class DatabaseIds {
    private final JdbcTemplate db;

    DatabaseIds(JdbcTemplate db) {
        this.db = db;
    }

    long ensureUserKey(UUID userUuid) {
        List<Long> existing = db.query("SELECT id FROM splitdebt_user_keys WHERE user_uuid=?",
                (r, n) -> r.getLong(1), userUuid);
        if (!existing.isEmpty()) return existing.get(0);
        try {
            db.update("INSERT INTO splitdebt_user_keys(user_uuid) VALUES(?)", userUuid);
        } catch (DuplicateKeyException ignored) {
            // Another request may have created the same bridge row concurrently.
        }
        return db.queryForObject("SELECT id FROM splitdebt_user_keys WHERE user_uuid=?", Long.class, userUuid);
    }

    long ensureGroupKey(UUID groupUuid) {
        List<Long> existing = db.query("SELECT id FROM splitdebt_group_keys WHERE group_uuid=?",
                (r, n) -> r.getLong(1), groupUuid);
        if (!existing.isEmpty()) return existing.get(0);
        try {
            db.update("INSERT INTO splitdebt_group_keys(group_uuid) VALUES(?)", groupUuid);
        } catch (DuplicateKeyException ignored) {
            // Another request may have created the same bridge row concurrently.
        }
        return db.queryForObject("SELECT id FROM splitdebt_group_keys WHERE group_uuid=?", Long.class, groupUuid);
    }

    UUID userUuid(long userKey) {
        List<String> rows = db.query("SELECT CAST(user_uuid AS VARCHAR) FROM splitdebt_user_keys WHERE id=?",
                (r, n) -> r.getString(1), userKey);
        if (rows.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "This account no longer exists.");
        }
        return UUID.fromString(rows.get(0));
    }

    UUID groupUuid(long groupKey) {
        List<String> rows = db.query("SELECT CAST(group_uuid AS VARCHAR) FROM splitdebt_group_keys WHERE id=?",
                (r, n) -> r.getString(1), groupKey);
        if (rows.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Group was not found.");
        }
        return UUID.fromString(rows.get(0));
    }

    Long findUserKeyByEmail(String normalizedEmail) {
        List<Long> rows = db.query("""
                SELECT k.id
                  FROM users u
                  JOIN splitdebt_user_keys k ON k.user_uuid=u.id
                 WHERE LOWER(u.email)=?
                """, (r, n) -> r.getLong(1), normalizedEmail);
        return rows.isEmpty() ? null : rows.get(0);
    }

    Long findGroupKeyByUuid(UUID groupUuid) {
        List<Long> rows = db.query("SELECT id FROM splitdebt_group_keys WHERE group_uuid=?",
                (r, n) -> r.getLong(1), groupUuid);
        return rows.isEmpty() ? null : rows.get(0);
    }
}
