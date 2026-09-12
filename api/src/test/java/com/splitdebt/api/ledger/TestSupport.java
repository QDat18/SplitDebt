package com.splitdebt.api.ledger;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.server.ResponseStatusException;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

abstract class TestSupport {
    @Autowired protected LedgerService ledger;
    @Autowired protected JdbcTemplate db;

    protected AuthFilter.User person(String displayName) {
        String local = displayName.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]", "");
        if (local.length() < 2) local = "user";
        String email = local + "." + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
        var created = ledger.register(displayName, email, null, "password123");
        long id = ((Number) created.get("id")).longValue();
        return new AuthFilter.User(id, email, displayName);
    }

    protected LedgerController.ExpenseInput expense(
            String title,
            long total,
            long payerId,
            String splitType,
            List<LedgerController.ParticipantInput> participants,
            List<LedgerController.ItemInput> items) {
        return new LedgerController.ExpenseInput(
                title, null, total, null, payerId, LocalDate.now(), null,
                splitType, participants, items == null ? List.of() : items);
    }

    protected LedgerController.ExpenseInput equal(long total, long payerId, List<Long> people) {
        return expense("Test expense", total, payerId, "EQUAL",
                people.stream().map(id -> new LedgerController.ParticipantInput(id, null, null, null)).toList(),
                List.of());
    }

    protected LedgerController.ParticipantInput amount(long userId, long amount) {
        return new LedgerController.ParticipantInput(userId, amount, null, null);
    }

    protected LedgerController.ParticipantInput percent(long userId, String percentage) {
        return new LedgerController.ParticipantInput(userId, null, new BigDecimal(percentage), null);
    }

    protected LedgerController.ParticipantInput weight(long userId, String weight) {
        return new LedgerController.ParticipantInput(userId, null, null, new BigDecimal(weight));
    }

    protected ResponseStatusException assertStatus(HttpStatus status, Runnable action) {
        ResponseStatusException error = assertThrows(ResponseStatusException.class, action::run);
        assertEquals(status, error.getStatusCode());
        return error;
    }
}
