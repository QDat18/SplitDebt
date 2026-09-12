package com.splitdebt.api.ledger;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class ExpenseSplitModeTests extends TestSupport {
    private record Fixture(AuthFilter.User owner, AuthFilter.User bob, AuthFilter.User charlie, LedgerService.Group group) {}

    private Fixture fixture() {
        var owner = person("Split Owner");
        var bob = person("Split Bob");
        var charlie = person("Split Charlie");
        var group = ledger.createGroup(owner, "Split Modes", null, "VND");
        ledger.addMember(group.id(), owner, bob.email());
        ledger.addMember(group.id(), owner, charlie.email());
        return new Fixture(owner, bob, charlie, group);
    }

    private Map<Long, Long> shares(LedgerService.Expense expense) {
        return expense.shares().stream().collect(Collectors.toMap(LedgerService.Share::userId, LedgerService.Share::amount));
    }

    @Test
    void equalSplitConservesMoneyWithDeterministicRounding() {
        var f = fixture();
        var saved = ledger.saveExpense(f.group.id(), null, f.owner,
                equal(100, f.owner.id(), List.of(f.charlie.id(), f.bob.id(), f.owner.id())));
        var values = saved.shares().stream().mapToLong(LedgerService.Share::amount).sorted().toArray();
        assertArrayEquals(new long[]{33, 33, 34}, values);
        assertEquals(100L, saved.shares().stream().mapToLong(LedgerService.Share::amount).sum());
    }

    @Test
    void exactAmountSplitIsStoredExactly() {
        var f = fixture();
        var input = expense("Exact", 100, f.owner.id(), "AMOUNT",
                List.of(amount(f.owner.id(), 10), amount(f.bob.id(), 30), amount(f.charlie.id(), 60)), List.of());
        var saved = ledger.saveExpense(f.group.id(), null, f.owner, input);
        assertEquals(Map.of(f.owner.id(), 10L, f.bob.id(), 30L, f.charlie.id(), 60L), shares(saved));
    }

    @Test
    void percentageSplitRequiresExactlyOneHundredPercentAndPreservesMinorUnits() {
        var f = fixture();
        var valid = expense("Percent", 101, f.owner.id(), "PERCENT",
                List.of(percent(f.owner.id(), "33"), percent(f.bob.id(), "33"), percent(f.charlie.id(), "34")), List.of());
        var saved = ledger.saveExpense(f.group.id(), null, f.owner, valid);
        assertEquals(101L, saved.shares().stream().mapToLong(LedgerService.Share::amount).sum());

        var invalid = expense("Percent bad", 100, f.owner.id(), "PERCENT",
                List.of(percent(f.owner.id(), "50"), percent(f.bob.id(), "49")), List.of());
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.saveExpense(f.group.id(), null, f.owner, invalid));
    }

    @Test
    void weightedSplitUsesRelativeWeights() {
        var f = fixture();
        var input = expense("Weight", 100, f.owner.id(), "WEIGHT",
                List.of(weight(f.owner.id(), "1"), weight(f.bob.id(), "2"), weight(f.charlie.id(), "1")), List.of());
        var saved = ledger.saveExpense(f.group.id(), null, f.owner, input);
        assertEquals(Map.of(f.owner.id(), 25L, f.bob.id(), 50L, f.charlie.id(), 25L), shares(saved));
    }

    @Test
    void itemSplitAggregatesEachMembersItemShares() {
        var f = fixture();
        var participants = List.of(
                new LedgerController.ParticipantInput(f.owner.id(), null, null, null),
                new LedgerController.ParticipantInput(f.bob.id(), null, null, null),
                new LedgerController.ParticipantInput(f.charlie.id(), null, null, null));
        var items = List.of(
                new LedgerController.ItemInput("Coffee", BigDecimal.ONE, 100L, 100L, List.of(f.owner.id(), f.bob.id())),
                new LedgerController.ItemInput("Lunch", BigDecimal.ONE, 200L, 200L, List.of(f.bob.id(), f.charlie.id())));
        var saved = ledger.saveExpense(f.group.id(), null, f.owner,
                expense("Items", 300, f.owner.id(), "ITEM", participants, items));

        assertEquals(Map.of(f.owner.id(), 50L, f.bob.id(), 150L, f.charlie.id(), 100L), shares(saved));
        assertEquals(2, saved.items().size());
        assertEquals(300L, saved.items().stream().mapToLong(LedgerService.ExpenseItem::totalPrice).sum());
        assertEquals(4, db.queryForObject("SELECT COUNT(*) FROM item_participants ip JOIN expense_items i ON i.id=ip.item_id WHERE i.expense_id=?",
                Integer.class, saved.id()));
    }

    @Test
    void invalidAmountWeightAndItemSplitsAreRejected() {
        var f = fixture();
        var amountBad = expense("Bad amount", 100, f.owner.id(), "AMOUNT",
                List.of(amount(f.owner.id(), 40), amount(f.bob.id(), 40)), List.of());
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.saveExpense(f.group.id(), null, f.owner, amountBad));

        var weightBad = expense("Bad weight", 100, f.owner.id(), "WEIGHT",
                List.of(weight(f.owner.id(), "1"), weight(f.bob.id(), "0")), List.of());
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.saveExpense(f.group.id(), null, f.owner, weightBad));

        var participants = List.of(
                new LedgerController.ParticipantInput(f.owner.id(), null, null, null),
                new LedgerController.ParticipantInput(f.bob.id(), null, null, null));
        var itemBad = expense("Bad item", 100, f.owner.id(), "ITEM", participants,
                List.of(new LedgerController.ItemInput("Only 90", BigDecimal.ONE, 90L, 90L, List.of(f.owner.id(), f.bob.id()))));
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.saveExpense(f.group.id(), null, f.owner, itemBad));
    }

    @Test
    void duplicateOrNonMemberParticipantsAndPayersAreRejected() {
        var f = fixture();
        var outsider = person("Split Outsider");
        var duplicate = expense("Duplicate", 100, f.owner.id(), "EQUAL",
                List.of(
                        new LedgerController.ParticipantInput(f.bob.id(), null, null, null),
                        new LedgerController.ParticipantInput(f.bob.id(), null, null, null)), List.of());
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.saveExpense(f.group.id(), null, f.owner, duplicate));

        assertStatus(HttpStatus.NOT_FOUND,
                () -> ledger.saveExpense(f.group.id(), null, f.owner, equal(100, outsider.id(), List.of(f.owner.id(), f.bob.id()))));

        assertStatus(HttpStatus.NOT_FOUND,
                () -> ledger.saveExpense(f.group.id(), null, f.owner, equal(100, f.owner.id(), List.of(f.owner.id(), outsider.id()))));
    }

    @Test
    void invalidCategoryAndUnsupportedSplitTypeAreRejected() {
        var f = fixture();
        var invalidCategory = new LedgerController.ExpenseInput(
                "Category", null, 100L, 99999999L, f.owner.id(), java.time.LocalDate.now(), null, "EQUAL",
                List.of(new LedgerController.ParticipantInput(f.owner.id(), null, null, null)), List.of());
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.saveExpense(f.group.id(), null, f.owner, invalidCategory));

        var invalidSplit = expense("Unsupported", 100, f.owner.id(), "RANDOM",
                List.of(new LedgerController.ParticipantInput(f.owner.id(), null, null, null)), List.of());
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.saveExpense(f.group.id(), null, f.owner, invalidSplit));
    }

    @Test
    void usdAmountsRoundTripUsingTwoDecimalMinorUnits() {
        var owner = person("Dollar Owner");
        var member = person("Dollar Member");
        var group = ledger.createGroup(owner, "USD Group", null, "USD");
        ledger.addMember(group.id(), owner, member.email());

        var saved = ledger.saveExpense(group.id(), null, owner,
                equal(1001, owner.id(), List.of(owner.id(), member.id()))); // $10.01
        assertEquals(1001L, saved.amount());
        var persisted = db.queryForObject("SELECT total_amount FROM expenses WHERE id=?",
                java.math.BigDecimal.class, saved.id());
        assertNotNull(persisted);
        assertEquals(0, persisted.compareTo(new java.math.BigDecimal("10.01")));
    }
}
