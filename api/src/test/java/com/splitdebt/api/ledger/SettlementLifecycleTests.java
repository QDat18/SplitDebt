package com.splitdebt.api.ledger;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class SettlementLifecycleTests extends TestSupport {
    private record Fixture(AuthFilter.User owner, AuthFilter.User debtor, AuthFilter.User third, LedgerService.Group group) {}

    private Fixture fixture() {
        var owner = person("Settlement Owner");
        var debtor = person("Settlement Debtor");
        var third = person("Settlement Third");
        var group = ledger.createGroup(owner, "Settlement", null, "VND");
        ledger.addMember(group.id(), owner, debtor.email());
        ledger.addMember(group.id(), owner, third.email());
        ledger.saveExpense(group.id(), null, owner, equal(100, owner.id(), List.of(owner.id(), debtor.id())));
        return new Fixture(owner, debtor, third, group);
    }

    @Test
    void twoSidedPaymentLifecycleClearsDebtOnlyAfterRecipientConfirms() {
        var f = fixture();
        assertEquals(50L, ledger.balances(f.group.id()).get(f.owner.id()));
        assertEquals(-50L, ledger.balances(f.group.id()).get(f.debtor.id()));

        var paid = ledger.recordSettlement(f.group.id(), f.debtor, f.owner.id(), 50, "BANK_TRANSFER");
        assertEquals("PAID", paid.status());
        assertNotNull(paid.paidAt());
        assertNull(paid.confirmedAt());

        // A PAID settlement is pending recipient confirmation, so raw balances remain unchanged.
        assertEquals(-50L, ledger.balances(f.group.id()).get(f.debtor.id()));
        var pendingDetail = ledger.detail(f.group.id(), f.debtor);
        assertEquals(0L, pendingDetail.effectiveBalances().get(f.debtor.id()),
                "UI-facing effective balance should reach zero immediately after the payer records a full payment.");
        assertTrue(pendingDetail.suggestions().isEmpty(),
                "Pending payments must not be suggested a second time.");

        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.confirmSettlement(paid.id(), f.debtor));
        var confirmed = ledger.confirmSettlement(paid.id(), f.owner);
        assertEquals("CONFIRMED", confirmed.status());
        assertNotNull(confirmed.confirmedAt());
        assertTrue(ledger.balances(f.group.id()).values().stream().allMatch(v -> v == 0));
        assertTrue(ledger.detail(f.group.id(), f.owner).suggestions().isEmpty());
        assertTrue(ledger.notifications(f.debtor, 20).stream()
                .anyMatch(n -> "SETTLEMENT_CONFIRMED".equals(n.get("type"))));
    }

    @Test
    void settlementCannotOverpayOrUseWrongDirection() {
        var f = fixture();
        assertStatus(HttpStatus.BAD_REQUEST,
                () -> ledger.recordSettlement(f.group.id(), f.debtor, f.owner.id(), 51, "CASH"));
        assertStatus(HttpStatus.BAD_REQUEST,
                () -> ledger.recordSettlement(f.group.id(), f.owner, f.debtor.id(), 50, "CASH"));
        assertStatus(HttpStatus.BAD_REQUEST,
                () -> ledger.recordSettlement(f.group.id(), f.debtor, f.debtor.id(), 1, "CASH"));
    }

    @Test
    void pendingPaymentReducesRemainingAmountAndPreventsDuplicateOverpayment() {
        var f = fixture();
        var first = ledger.recordSettlement(f.group.id(), f.debtor, f.owner.id(), 30, "CASH");
        assertEquals("PAID", first.status());
        assertStatus(HttpStatus.BAD_REQUEST,
                () -> ledger.recordSettlement(f.group.id(), f.debtor, f.owner.id(), 21, "CASH"));
        var second = ledger.recordSettlement(f.group.id(), f.debtor, f.owner.id(), 20, "CASH");
        assertEquals("PAID", second.status());
        assertTrue(ledger.detail(f.group.id(), f.debtor).suggestions().isEmpty());
    }

    @Test
    void payerOrOwnerCanCancelPendingPaymentButOtherMemberCannot() {
        var f = fixture();
        var paid = ledger.recordSettlement(f.group.id(), f.debtor, f.owner.id(), 50, "CASH");
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.cancelSettlement(paid.id(), f.third));

        var cancelled = ledger.cancelSettlement(paid.id(), f.owner);
        assertEquals("CANCELLED", cancelled.status());
        assertEquals(1, ledger.detail(f.group.id(), f.debtor).suggestions().size(),
                "Cancelling a pending record should make the debt payable again.");
    }

    @Test
    void confirmedSettlementCannotBeCancelledOrConfirmedTwice() {
        var f = fixture();
        var paid = ledger.recordSettlement(f.group.id(), f.debtor, f.owner.id(), 50, "CASH");
        ledger.confirmSettlement(paid.id(), f.owner);
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.confirmSettlement(paid.id(), f.owner));
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.cancelSettlement(paid.id(), f.owner));
    }

    @Test
    void unknownSettlementReturnsNotFound() {
        var f = fixture();
        assertStatus(HttpStatus.NOT_FOUND, () -> ledger.confirmSettlement(999999L, f.owner));
        assertStatus(HttpStatus.NOT_FOUND, () -> ledger.cancelSettlement(999999L, f.owner));
    }
}
