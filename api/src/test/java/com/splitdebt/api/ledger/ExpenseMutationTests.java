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
class ExpenseMutationTests extends TestSupport {
    @Test
    void payerAndOwnerCanEditButUnrelatedMemberCannot() {
        var owner = person("Edit Owner");
        var payer = person("Edit Payer");
        var viewer = person("Edit Viewer");
        var group = ledger.createGroup(owner, "Editing", null, "VND");
        ledger.addMember(group.id(), owner, payer.email());
        ledger.addMember(group.id(), owner, viewer.email());

        var original = ledger.saveExpense(group.id(), null, payer,
                equal(90, payer.id(), List.of(owner.id(), payer.id(), viewer.id())));

        var viewerEdit = equal(120, payer.id(), List.of(owner.id(), payer.id(), viewer.id()));
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.saveExpense(group.id(), original.id(), viewer, viewerEdit));

        var ownerEdit = equal(120, payer.id(), List.of(owner.id(), payer.id(), viewer.id()));
        var edited = ledger.saveExpense(group.id(), original.id(), owner, ownerEdit);
        assertEquals(120, edited.amount());
        assertEquals(original.id(), edited.id());

        var payerEdit = equal(150, payer.id(), List.of(owner.id(), payer.id(), viewer.id()));
        assertEquals(150, ledger.saveExpense(group.id(), original.id(), payer, payerEdit).amount());
    }

    @Test
    void deleteExpenseRemovesDetailsAndRecalculatesLedger() {
        var owner = person("Delete Owner");
        var member = person("Delete Member");
        var group = ledger.createGroup(owner, "Delete", null, "VND");
        ledger.addMember(group.id(), owner, member.email());

        var expense = ledger.saveExpense(group.id(), null, owner,
                equal(100, owner.id(), List.of(owner.id(), member.id())));
        assertEquals(50L, ledger.balances(group.id()).get(owner.id()));
        assertEquals(-50L, ledger.balances(group.id()).get(member.id()));
        assertTrue(db.queryForObject("SELECT COUNT(*) FROM debts WHERE group_id=?", Integer.class, group.id()) > 0);

        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.deleteExpense(group.id(), expense.id(), member));
        ledger.deleteExpense(group.id(), expense.id(), owner);

        assertTrue(ledger.detail(group.id(), owner).expenses().isEmpty());
        assertTrue(ledger.balances(group.id()).values().stream().allMatch(v -> v == 0));
        assertEquals(0, db.queryForObject("SELECT COUNT(*) FROM expense_participants WHERE expense_id=?", Integer.class, expense.id()));
        assertEquals(0, db.queryForObject("SELECT COUNT(*) FROM expense_shares WHERE expense_id=?", Integer.class, expense.id()));
        assertEquals(0, db.queryForObject("SELECT COUNT(*) FROM debts WHERE group_id=?", Integer.class, group.id()));
    }

    @Test
    void missingExpenseReturnsNotFound() {
        var owner = person("Missing Owner");
        var group = ledger.createGroup(owner, "Missing", null, "VND");
        assertStatus(HttpStatus.NOT_FOUND, () -> ledger.deleteExpense(group.id(), 999999L, owner));
        assertStatus(HttpStatus.NOT_FOUND, () -> ledger.saveExpense(group.id(), 999999L, owner,
                equal(100, owner.id(), List.of(owner.id()))));
    }
}
