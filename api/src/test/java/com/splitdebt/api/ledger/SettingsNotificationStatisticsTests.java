package com.splitdebt.api.ledger;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class SettingsNotificationStatisticsTests extends TestSupport {
    @Test
    void userSettingsHaveDefaultsAndSupportPartialUpdates() {
        var user = person("Settings User");
        Map<String, Object> defaults = ledger.userSettings(user);
        assertEquals("vi", defaults.get("language"));
        assertEquals("SYSTEM", defaults.get("theme"));
        assertEquals(Boolean.TRUE, defaults.get("notifyOnNewExpense"));

        var updated = ledger.updateUserSettings(user,
                new LedgerController.UserSettingsInput(true, "en", false, false, true, "dark"));
        assertEquals(Boolean.TRUE, updated.get("biometricsEnabled"));
        assertEquals("en", updated.get("language"));
        assertEquals("DARK", updated.get("theme"));
        assertEquals(Boolean.FALSE, updated.get("notifyOnDebtReminder"));
        assertEquals(Boolean.FALSE, updated.get("notifyOnNewExpense"));

        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.updateUserSettings(user,
                new LedgerController.UserSettingsInput(null, null, null, null, null, "neon")));
    }

    @Test
    void groupSettingsAreReadableByMembersButWritableOnlyByOwner() {
        var owner = person("Group Settings Owner");
        var member = person("Group Settings Member");
        var group = ledger.createGroup(owner, "Settings", null, "VND");
        ledger.addMember(group.id(), owner, member.email());

        assertEquals("VND", ledger.groupSettings(group.id(), member).get("currencyCode"));
        assertStatus(HttpStatus.FORBIDDEN, () -> ledger.updateGroupSettings(group.id(), member,
                new LedgerController.GroupSettingsInput(10, "OFF", "VND", 0, true, 1000L, true)));

        var updated = ledger.updateGroupSettings(group.id(), owner,
                new LedgerController.GroupSettingsInput(10, "OFF", "VND", 0, false, 5_000_000L, false));
        assertEquals(10, updated.get("autoFreezeDay"));
        assertEquals(5_000_000L, updated.get("monthlyBudgetLimit"));
        assertEquals(Boolean.FALSE, updated.get("imageOptimizationEnabled"));
        assertEquals(Boolean.FALSE, updated.get("smartSettlementEnabled"));

        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.updateGroupSettings(group.id(), owner,
                new LedgerController.GroupSettingsInput(32, null, null, null, null, null, null)));
    }

    @Test
    void currencyAndDecimalScaleCannotChangeAfterFinancialRecordsExist() {
        var owner = person("Locked Settings Owner");
        var group = ledger.createGroup(owner, "Locked", null, "VND");
        ledger.saveExpense(group.id(), null, owner, equal(100, owner.id(), List.of(owner.id())));

        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.updateGroupSettings(group.id(), owner,
                new LedgerController.GroupSettingsInput(null, null, "USD", 2, null, null, null)));

        // Non-financial settings can still change.
        var updated = ledger.updateGroupSettings(group.id(), owner,
                new LedgerController.GroupSettingsInput(null, "OFF", "VND", 0, false, 123L, false));
        assertEquals(Boolean.FALSE, updated.get("smartSettlementEnabled"));
        assertEquals(123L, updated.get("monthlyBudgetLimit"));
    }

    @Test
    void expenseNotificationIsScopedToParticipantAndCanOnlyBeMarkedByItsOwner() {
        var owner = person("Notification Owner");
        var member = person("Notification Member");
        var outsider = person("Notification Outsider");
        var group = ledger.createGroup(owner, "Notify", null, "VND");
        ledger.addMember(group.id(), owner, member.email());
        ledger.saveExpense(group.id(), null, owner, equal(100, owner.id(), List.of(owner.id(), member.id())));

        var notifications = ledger.notifications(member, 20);
        assertFalse(notifications.isEmpty());
        var expenseNotification = notifications.stream()
                .filter(n -> "NEW_EXPENSE".equals(n.get("type"))).findFirst().orElseThrow();
        long id = ((Number) expenseNotification.get("id")).longValue();
        assertEquals(Boolean.FALSE, expenseNotification.get("isRead"));

        assertStatus(HttpStatus.NOT_FOUND, () -> ledger.markNotificationRead(outsider, id));
        ledger.markNotificationRead(member, id);
        assertEquals(Boolean.TRUE, ledger.notifications(member, 20).stream()
                .filter(n -> ((Number) n.get("id")).longValue() == id)
                .findFirst().orElseThrow().get("isRead"));
    }

    @Test
    void openingNotificationCenterCanMarkAllNotificationsReadAtOnce() {
        var owner = person("Read All Owner");
        var member = person("Read All Member");
        var group = ledger.createGroup(owner, "Read All", null, "VND");
        ledger.addMember(group.id(), owner, member.email());
        ledger.saveExpense(group.id(), null, owner, equal(100, owner.id(), List.of(owner.id(), member.id())));

        assertTrue(ledger.notifications(member, 20).stream().anyMatch(n -> Boolean.FALSE.equals(n.get("isRead"))));
        assertTrue(ledger.markAllNotificationsRead(member) >= 1);
        assertTrue(ledger.notifications(member, 20).stream().allMatch(n -> Boolean.TRUE.equals(n.get("isRead"))));
    }

    @Test
    void disabledNewExpenseNotificationIsRespected() {
        var owner = person("Mute Owner");
        var member = person("Mute Member");
        var group = ledger.createGroup(owner, "Muted", null, "VND");
        ledger.addMember(group.id(), owner, member.email());
        ledger.updateUserSettings(member,
                new LedgerController.UserSettingsInput(null, null, null, false, null, null));

        ledger.saveExpense(group.id(), null, owner, equal(100, owner.id(), List.of(owner.id(), member.id())));
        assertTrue(ledger.notifications(member, 20).stream()
                .noneMatch(n -> "NEW_EXPENSE".equals(n.get("type"))));
    }

    @Test
    void statisticsAggregateTotalCategoryAndPayerAndEnforceRange() {
        var owner = person("Stats Owner");
        var member = person("Stats Member");
        var group = ledger.createGroup(owner, "Stats", null, "VND");
        ledger.addMember(group.id(), owner, member.email());
        long categoryId = ((Number) ledger.categories().get(0).get("id")).longValue();

        var input1 = new LedgerController.ExpenseInput(
                "Food", null, 120L, categoryId, owner.id(), LocalDate.now(), null, "EQUAL",
                List.of(new LedgerController.ParticipantInput(owner.id(), null, null, null),
                        new LedgerController.ParticipantInput(member.id(), null, null, null)), List.of());
        ledger.saveExpense(group.id(), null, owner, input1);
        ledger.saveExpense(group.id(), null, member,
                equal(80, member.id(), List.of(owner.id(), member.id())));

        Map<String, Object> day = ledger.statistics(group.id(), owner, "DAY");
        assertEquals("DAY", day.get("range"));
        assertEquals(200L, day.get("totalExpense"));
        assertEquals(120L, day.get("mySpent"));
        assertFalse(((List<?>) day.get("byCategory")).isEmpty());
        assertEquals(2, ((List<?>) day.get("byPayer")).size());

        assertEquals("MONTH", ledger.statistics(group.id(), owner, "month").get("range"));
        assertEquals("YEAR", ledger.statistics(group.id(), owner, "YEAR").get("range"));
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.statistics(group.id(), owner, "ALL"));
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.statistics(group.id(), owner, "WEEK"));
    }

    @Test
    void activitySupportsPaginationAndOnlyContainsAccessibleGroups() {
        var owner = person("Activity Owner");
        var outsider = person("Activity Outsider");
        var group = ledger.createGroup(owner, "Activity", null, "VND");
        ledger.saveExpense(group.id(), null, owner, equal(10, owner.id(), List.of(owner.id())));
        ledger.saveExpense(group.id(), null, owner, equal(20, owner.id(), List.of(owner.id())));

        var page1 = ledger.activity(owner, 1, 0);
        assertEquals(1, page1.items().size());
        assertEquals(1, page1.nextOffset());
        var page2 = ledger.activity(owner, 1, page1.nextOffset());
        assertEquals(1, page2.items().size());
        assertNotEquals(page1.items().get(0).id(), page2.items().get(0).id());

        assertTrue(ledger.activity(outsider, 20, 0).items().isEmpty());
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.activity(owner, 0, 0));
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.activity(owner, 10, -1));
    }

    @Test
    void schemaSeedsExpectedCoreCategories() {
        var categories = ledger.categories();
        assertTrue(categories.size() >= 6);
        var names = categories.stream().map(c -> c.get("name").toString()).toList();
        assertTrue(names.containsAll(List.of("Ăn uống", "Di chuyển", "Mua sắm", "Khách sạn", "Giải trí", "Khác")));
    }
}
