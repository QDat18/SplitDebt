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
class GroupLifecycleTests extends TestSupport {
    @Test
    void createGroupCreatesOwnerMembershipInviteCodeAndSettings() {
        var owner = person("Owner User");
        var group = ledger.createGroup(owner, "Hanoi Trip", "Weekend", "vnd");

        assertEquals(owner.id(), group.ownerId());
        assertEquals("VND", group.currency());
        assertEquals(0, group.decimalScale());
        assertEquals(1, group.memberCount());
        assertNotNull(group.inviteCode());
        assertFalse(group.inviteCode().isBlank());

        var detail = ledger.detail(group.id(), owner);
        assertEquals(1, detail.members().size());
        assertEquals("OWNER", detail.members().get(0).role());

        var settings = ledger.groupSettings(group.id(), owner);
        assertEquals("VND", settings.get("currencyCode"));
        assertEquals(0, settings.get("decimalScale"));
        assertEquals(Boolean.TRUE, settings.get("smartSettlementEnabled"));
    }

    @Test
    void onlySupportedCurrenciesCanBeUsed() {
        var owner = person("Currency Owner");
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.createGroup(owner, "Bad", null, "JPY"));
    }

    @Test
    void inviteCodeJoinIsCaseInsensitiveAndNotifiesOwner() {
        var owner = person("Invite Owner");
        var member = person("Invite Member");
        var group = ledger.createGroup(owner, "Invite Group", null, "VND");

        var joined = ledger.joinGroup(member, group.inviteCode().toLowerCase());
        assertEquals(group.id(), joined.id());
        assertEquals(2, joined.memberCount());
        assertTrue(ledger.detail(group.id(), member).members().stream().anyMatch(m -> m.id() == member.id()));
        assertTrue(ledger.notifications(owner, 20).stream()
                .anyMatch(n -> "MEMBER_JOINED".equals(n.get("type"))));
    }

    @Test
    void joiningUnknownInviteCodeReturnsNotFound() {
        var member = person("Unknown Joiner");
        assertStatus(HttpStatus.NOT_FOUND, () -> ledger.joinGroup(member, "DOESNOTEXIST"));
    }

    @Test
    void ownerCanAddMemberButOrdinaryMemberCannotManageMembership() {
        var owner = person("Group Owner");
        var member = person("Group Member");
        var third = person("Third Member");
        var group = ledger.createGroup(owner, "Team", null, "VND");

        ledger.addMember(group.id(), owner, member.email());
        assertEquals(2, ledger.detail(group.id(), owner).members().size());
        assertStatus(HttpStatus.FORBIDDEN, () -> ledger.addMember(group.id(), member, third.email()));
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.addMember(group.id(), owner, "missing@example.com"));
    }

    @Test
    void ownerCanAddMemberByPhoneNumber() {
        var owner = person("Phone Owner");
        String email = "phone.member." + java.util.UUID.randomUUID().toString().substring(0, 8) + "@example.com";
        var created = ledger.register("Phone Member", email, "+84 912 345 678", "password123");
        long memberId = ((Number) created.get("id")).longValue();
        var member = new AuthFilter.User(memberId, email, "Phone Member");
        var group = ledger.createGroup(owner, "Phone Group", null, "VND");

        ledger.addMember(group.id(), owner, "0912345678");

        assertTrue(ledger.detail(group.id(), owner).members().stream().anyMatch(m -> m.id() == member.id()));
        assertEquals("0912345678", ledger.detail(group.id(), owner).members().stream()
                .filter(m -> m.id() == member.id()).findFirst().orElseThrow().phone());
    }

    @Test
    void ownerCannotBeRemovedAndMemberWithDebtCannotBeRemoved() {
        var owner = person("Removal Owner");
        var member = person("Removal Member");
        var group = ledger.createGroup(owner, "Debt Group", null, "VND");
        ledger.addMember(group.id(), owner, member.email());

        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.removeMember(group.id(), owner, owner.id()));

        ledger.saveExpense(group.id(), null, owner, equal(100, owner.id(), List.of(owner.id(), member.id())));
        assertEquals(-50L, ledger.balances(group.id()).get(member.id()));
        assertStatus(HttpStatus.BAD_REQUEST, () -> ledger.removeMember(group.id(), owner, member.id()));
    }

    @Test
    void zeroBalanceMemberCanLeaveAndRejoinWithSameMembershipRecord() {
        var owner = person("Rejoin Owner");
        var member = person("Rejoin Member");
        var group = ledger.createGroup(owner, "Rejoin", null, "VND");
        ledger.addMember(group.id(), owner, member.email());
        int before = db.queryForObject(
                "SELECT COUNT(*) FROM group_members WHERE group_id=? AND user_id=?",
                Integer.class, group.id(), member.id());

        ledger.removeMember(group.id(), owner, member.id());
        assertStatus(HttpStatus.NOT_FOUND, () -> ledger.detail(group.id(), member));
        ledger.joinGroup(member, group.inviteCode());

        int after = db.queryForObject(
                "SELECT COUNT(*) FROM group_members WHERE group_id=? AND user_id=?",
                Integer.class, group.id(), member.id());
        assertEquals(before, after, "Rejoin should reactivate the existing membership instead of duplicating it.");
        assertEquals(2, ledger.detail(group.id(), owner).members().size());
    }
}
