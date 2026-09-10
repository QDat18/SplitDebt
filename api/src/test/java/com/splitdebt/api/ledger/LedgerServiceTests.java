package com.splitdebt.api.ledger;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(properties={
        "spring.datasource.url=jdbc:h2:mem:ledger;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;NON_KEYWORDS=GROUPS;DB_CLOSE_DELAY=-1",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "splitdebt.jwt-secret=test-secret-long-enough-for-tests"
})
@Transactional
class LedgerServiceTests {
    @Autowired LedgerService ledger;

    AuthFilter.User person(String name) {
        String email = name.toLowerCase() + System.nanoTime() + "@example.com";
        var created = ledger.register(name, email, null, "password123");
        long id = ((Number) created.get("id")).longValue();
        return new AuthFilter.User(id, email, name);
    }

    LedgerController.ExpenseInput equal(long payer, long amount, List<Long> people) {
        return new LedgerController.ExpenseInput(
                "Dinner", null, amount, null, payer, LocalDate.now(), null, "EQUAL",
                people.stream().map(id -> new LedgerController.ParticipantInput(id, null, null, null)).toList(),
                List.of());
    }

    @Test
    void expenseSettlementAndAccessControl() {
        var alice = person("Alice");
        var bob = person("Bob");
        var outsider = person("Outsider");
        var group = ledger.createGroup(alice, "Weekend", "Trip", "USD");
        ledger.addMember(group.id(), alice, bob.email());
        ledger.saveExpense(group.id(), null, alice, equal(alice.id(), 10000, List.of(alice.id(), bob.id())));

        var detail = ledger.detail(group.id(), bob);
        assertEquals(1, detail.expenses().size());
        assertEquals(5000L, detail.balances().get(alice.id()));
        assertEquals(-5000L, detail.balances().get(bob.id()));
        assertThrows(ResponseStatusException.class, () -> ledger.detail(group.id(), outsider));
        assertThrows(ResponseStatusException.class, () -> ledger.addMember(group.id(), bob, outsider.email()));

        var paid = ledger.recordSettlement(group.id(), bob, alice.id(), 5000, "CASH");
        assertEquals("PAID", paid.status());
        assertEquals(-5000L, ledger.detail(group.id(), bob).balances().get(bob.id()));
        var confirmed = ledger.confirmSettlement(paid.id(), alice);
        assertEquals("CONFIRMED", confirmed.status());
        assertTrue(ledger.detail(group.id(), alice).suggestions().isEmpty());
    }

    @Test
    void flexibleSplitsConserveMoney() {
        var alice = person("AliceP");
        var bob = person("BobP");
        var group = ledger.createGroup(alice, "Percent", null, "VND");
        ledger.addMember(group.id(), alice, bob.email());
        var input = new LedgerController.ExpenseInput(
                "Taxi", null, 100L, null, alice.id(), LocalDate.now(), null, "PERCENT",
                List.of(
                        new LedgerController.ParticipantInput(alice.id(), null, new java.math.BigDecimal("33"), null),
                        new LedgerController.ParticipantInput(bob.id(), null, new java.math.BigDecimal("67"), null)),
                List.of());
        var expense = ledger.saveExpense(group.id(), null, alice, input);
        assertEquals(100L, expense.shares().stream().mapToLong(LedgerService.Share::amount).sum());
    }

    @Test
    void penniesAreConserved() {
        assertEquals(Map.of(1L, 34L, 2L, 33L, 3L, 33L), LedgerMath.split(100, List.of(3L, 2L, 1L)));
    }
}
