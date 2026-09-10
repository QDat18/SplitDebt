package com.splitdebt.api.ledger;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeMap;
import java.util.UUID;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class LedgerService {
    public record Profile(long id, String email, String name, String phone, String avatarUrl) {}
    public record AuthResult(String token, Profile user) {}
    public record CurrencyBalance(String currency, long receivable, long payable) {}
    public record ActivityItem(long id, String title, String kind, long amount, String currency,
                               long groupId, String groupName, String createdAt, String payerName, String status) {}
    public record ActivityPage(List<ActivityItem> items, Integer nextOffset) {}
    public record Group(long id, String name, String description, String inviteCode, long ownerId,
                        String createdAt, int memberCount, long balance, long total, String currency,
                        int decimalScale, boolean smartSettlementEnabled) {}
    public record Member(long id, String email, String name, String avatarUrl, String role, String status) {}
    public record Share(long userId, String splitType, long amount, BigDecimal percentage, BigDecimal weight) {}
    public record ItemShare(long userId, long shareAmount) {}
    public record ExpenseItem(long id, String itemName, BigDecimal quantity, long unitPrice, long totalPrice,
                              List<ItemShare> participants) {}
    public record Expense(long id, String title, String description, long amount, Long categoryId,
                          String categoryName, long payerId, String expenseDate, String receiptUrl,
                          String createdAt, String updatedAt, List<Share> shares, List<ExpenseItem> items) {}
    public record Settlement(long id, long debtorId, long creditorId, long amount, String status,
                             String paymentMethod, String requestedAt, String paidAt, String confirmedAt) {}
    public record Detail(Group group, List<Member> members, List<Expense> expenses, List<Settlement> settlements,
                         Map<Long, Long> balances, List<LedgerMath.Transfer> suggestions) {}
    public record Overview(Profile me, List<Group> groups, List<CurrencyBalance> balances, long unreadNotifications) {}

    private record GroupMeta(long id, String name, String description, String inviteCode, long ownerId,
                             String createdAt, String currency, int scale, boolean smartSettlementEnabled) {}
    private record SettlementRow(long id, long groupId, long debtorId, long creditorId, long amount,
                                 String status, String paymentMethod, String requestedAt, String paidAt, String confirmedAt) {}

    private final JdbcTemplate db;
    private final PasswordService passwords;
    private final JwtService jwt;

    public LedgerService(JdbcTemplate db, PasswordService passwords, JwtService jwt) {
        this.db = db;
        this.passwords = passwords;
        this.jwt = jwt;
    }

    // ---------------------------------------------------------------------
    // Authentication and profile
    // ---------------------------------------------------------------------

    @Transactional
    public Map<String, Object> register(String fullName, String email, String phone, String password) {
        String normalizedEmail = normalizeEmail(email);
        String normalizedName = clean(fullName, 100);
        require(normalizedName.length() >= 2, "Full name must contain at least 2 characters.");
        require(password != null && password.length() >= 8, "Password must contain at least 8 characters.");
        String normalizedPhone = phone == null || phone.isBlank() ? null : clean(phone, 20);
        try {
            long id = insertAndKey(
                    "INSERT INTO users(full_name,email,phone,password_hash,created_at,updated_at) VALUES(?,?,?,?,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)",
                    normalizedName, normalizedEmail, normalizedPhone, passwords.hash(password));
            ensureUserSettings(id);
            return Map.of("id", id, "message", "Account created successfully. You can now sign in.");
        } catch (DuplicateKeyException e) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email is already in use.");
        }
    }

    @Transactional(readOnly = true)
    public AuthResult login(String email, String password) {
        String normalizedEmail = normalizeEmail(email);
        var rows = db.query("SELECT id,email,full_name,phone,avatar_url,password_hash FROM users WHERE email=?",
                (r, n) -> Map.<String, Object>of(
                        "id", r.getLong("id"),
                        "email", r.getString("email"),
                        "name", r.getString("full_name"),
                        "password", r.getString("password_hash")), normalizedEmail);
        if (rows.isEmpty() || !passwords.matches(password, (String) rows.get(0).get("password"))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email or password is incorrect.");
        }
        Map<String, Object> row = rows.get(0);
        long id = (long) row.get("id");
        Profile profile = profileById(id);
        return new AuthResult(jwt.issue(id, profile.email(), profile.name()), profile);
    }

    @Transactional
    public Profile profile(AuthFilter.User user) {
        ensureActiveUser(user.id());
        ensureUserSettings(user.id());
        return profileById(user.id());
    }

    @Transactional
    public Profile updateProfile(AuthFilter.User user, String fullName, String phone, String avatarUrl) {
        ensureActiveUser(user.id());
        db.update("UPDATE users SET full_name=?, phone=?, avatar_url=?, updated_at=CURRENT_TIMESTAMP WHERE id=?",
                clean(fullName, 100), blankToNull(phone, 20), blankToNull(avatarUrl, 2000), user.id());
        return profileById(user.id());
    }

    private Profile profileById(long id) {
        return db.queryForObject("SELECT id,email,full_name,phone,avatar_url FROM users WHERE id=?",
                (r, n) -> new Profile(r.getLong("id"), r.getString("email"), r.getString("full_name"),
                        r.getString("phone"), r.getString("avatar_url")), id);
    }

    private void ensureActiveUser(long userId) {
        if (count("SELECT COUNT(*) FROM users WHERE id=?", userId) == 0) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "This account no longer exists.");
        }
    }

    // ---------------------------------------------------------------------
    // Settings
    // ---------------------------------------------------------------------

    @Transactional
    public Map<String, Object> userSettings(AuthFilter.User user) {
        ensureUserSettings(user.id());
        return db.queryForObject("SELECT * FROM user_settings WHERE user_id=?", (r, n) -> {
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("biometricsEnabled", r.getBoolean("biometrics_enabled"));
            out.put("language", r.getString("language"));
            out.put("notifyOnDebtReminder", r.getBoolean("notify_on_debt_reminder"));
            out.put("notifyOnNewExpense", r.getBoolean("notify_on_new_expense"));
            out.put("notifyOnSettlement", r.getBoolean("notify_on_settlement"));
            out.put("theme", r.getString("theme"));
            return out;
        }, user.id());
    }

    @Transactional
    public Map<String, Object> updateUserSettings(AuthFilter.User user, LedgerController.UserSettingsInput input) {
        ensureUserSettings(user.id());
        Map<String, Object> current = userSettings(user);
        boolean biometrics = valueOr(input.biometricsEnabled(), (Boolean) current.get("biometricsEnabled"));
        String language = valueOrText(input.language(), (String) current.get("language"), 20).toLowerCase(Locale.ROOT);
        boolean debt = valueOr(input.notifyOnDebtReminder(), (Boolean) current.get("notifyOnDebtReminder"));
        boolean expense = valueOr(input.notifyOnNewExpense(), (Boolean) current.get("notifyOnNewExpense"));
        boolean settlement = valueOr(input.notifyOnSettlement(), (Boolean) current.get("notifyOnSettlement"));
        String theme = valueOrText(input.theme(), (String) current.get("theme"), 20).toUpperCase(Locale.ROOT);
        require(Set.of("SYSTEM", "LIGHT", "DARK").contains(theme), "Theme must be SYSTEM, LIGHT or DARK.");
        db.update("UPDATE user_settings SET biometrics_enabled=?,language=?,notify_on_debt_reminder=?,notify_on_new_expense=?,notify_on_settlement=?,theme=?,updated_at=CURRENT_TIMESTAMP WHERE user_id=?",
                biometrics, language, debt, expense, settlement, theme, user.id());
        return userSettings(user);
    }

    private void ensureUserSettings(long userId) {
        if (count("SELECT COUNT(*) FROM user_settings WHERE user_id=?", userId) == 0) {
            db.update("INSERT INTO user_settings(created_at,updated_at,biometrics_enabled,language,notify_on_debt_reminder,notify_on_new_expense,notify_on_settlement,theme,user_id) VALUES(CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,FALSE,'vi',TRUE,TRUE,TRUE,'SYSTEM',?)",
                    userId);
        }
    }

    @Transactional
    public Map<String, Object> groupSettings(long groupId, AuthFilter.User user) {
        requireMember(groupId, user.id());
        GroupMeta meta = groupMeta(groupId);
        return readGroupSettings(meta.id());
    }

    @Transactional
    public Map<String, Object> updateGroupSettings(long groupId, AuthFilter.User user,
                                                    LedgerController.GroupSettingsInput input) {
        lockGroup(groupId, user.id());
        requireOwner(groupId, user.id());
        Map<String, Object> current = readGroupSettings(groupId);
        Integer freeze = input.autoFreezeDay() == null ? (Integer) current.get("autoFreezeDay") : input.autoFreezeDay();
        if (freeze != null) require(freeze >= 1 && freeze <= 31, "Auto-freeze day must be between 1 and 31.");
        String cloud = valueOrText(input.cloudStorageSync(), (String) current.get("cloudStorageSync"), 30).toUpperCase(Locale.ROOT);
        String currency = valueOrText(input.currencyCode(), (String) current.get("currencyCode"), 10).toUpperCase(Locale.ROOT);
        require(Set.of("VND", "USD", "EUR").contains(currency), "Currency must be VND, USD or EUR.");
        int scale = input.decimalScale() == null ? (Integer) current.get("decimalScale") : input.decimalScale();
        require(scale >= 0 && scale <= 4, "Decimal scale must be between 0 and 4.");
        boolean hasMoney = count("SELECT COUNT(*) FROM expenses WHERE group_id=?", groupId) > 0
                || count("SELECT COUNT(*) FROM settlements WHERE group_id=?", groupId) > 0;
        if (hasMoney) {
            require(currency.equals(current.get("currencyCode")) && scale == (Integer) current.get("decimalScale"),
                    "Currency and decimal scale cannot change after financial records exist.");
        }
        boolean image = valueOr(input.imageOptimizationEnabled(), (Boolean) current.get("imageOptimizationEnabled"));
        boolean smart = valueOr(input.smartSettlementEnabled(), (Boolean) current.get("smartSettlementEnabled"));
        Long budget = input.monthlyBudgetLimit() == null ? (Long) current.get("monthlyBudgetLimit") : input.monthlyBudgetLimit();
        if (budget != null) require(budget >= 0, "Monthly budget cannot be negative.");
        db.update("UPDATE group_settings SET auto_freeze_day=?,cloud_storage_sync=?,currency_code=?,decimal_scale=?,image_optimization_enabled=?,monthly_budget_limit=?,smart_settlement_enabled=?,updated_at=CURRENT_TIMESTAMP WHERE group_id=?",
                freeze, cloud, currency, scale, image,
                budget == null ? null : minorToDb(budget, scale), smart, groupId);
        return readGroupSettings(groupId);
    }

    private Map<String, Object> readGroupSettings(long groupId) {
        ensureGroupSettings(groupId, "VND");
        return db.queryForObject("SELECT * FROM group_settings WHERE group_id=?", (r, n) -> {
            int scale = r.getInt("decimal_scale");
            BigDecimal budget = r.getBigDecimal("monthly_budget_limit");
            Map<String, Object> out = new LinkedHashMap<>();
            Object freeze = r.getObject("auto_freeze_day");
            out.put("autoFreezeDay", freeze == null ? null : ((Number) freeze).intValue());
            out.put("cloudStorageSync", r.getString("cloud_storage_sync"));
            out.put("currencyCode", r.getString("currency_code"));
            out.put("decimalScale", scale);
            out.put("imageOptimizationEnabled", r.getBoolean("image_optimization_enabled"));
            out.put("monthlyBudgetLimit", budget == null ? null : dbToMinor(budget, scale));
            out.put("smartSettlementEnabled", r.getBoolean("smart_settlement_enabled"));
            return out;
        }, groupId);
    }

    // ---------------------------------------------------------------------
    // Group list / overview / activity
    // ---------------------------------------------------------------------

    @Transactional(isolation = Isolation.REPEATABLE_READ)
    public Overview overview(AuthFilter.User user) {
        Profile me = profile(user);
        List<Group> groups = groups(user);
        Map<String, long[]> byCurrency = new TreeMap<>();
        for (Group group : groups) {
            long[] pair = byCurrency.computeIfAbsent(group.currency(), k -> new long[2]);
            if (group.balance() >= 0) pair[0] += group.balance(); else pair[1] += -group.balance();
        }
        List<CurrencyBalance> balances = byCurrency.entrySet().stream()
                .map(e -> new CurrencyBalance(e.getKey(), e.getValue()[0], e.getValue()[1])).toList();
        long unread = count("SELECT COUNT(*) FROM notifications WHERE user_id=? AND is_read=FALSE", user.id());
        return new Overview(me, groups, balances, unread);
    }

    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public ActivityPage activity(AuthFilter.User user, int limit, int offset) {
        require(limit >= 1 && limit <= 100 && offset >= 0 && offset <= 1_000_000, "Invalid activity page.");
        String sql = """
                SELECT * FROM (
                  SELECT e.id,e.title,'expense' kind,e.total_amount amount,g.id group_id,g.name group_name,
                         e.created_at,u.full_name payer_name,NULL status,COALESCE(gs.currency_code,'VND') currency_code,COALESCE(gs.decimal_scale,0) decimal_scale
                    FROM expenses e
                    JOIN groups g ON g.id=e.group_id
                    JOIN group_members gm ON gm.group_id=g.id AND gm.user_id=? AND gm.status='ACTIVE'
                    JOIN users u ON u.id=e.payer_id
                    LEFT JOIN group_settings gs ON gs.group_id=g.id
                  UNION ALL
                  SELECT s.id,'Settlement' title,'settlement' kind,s.amount,g.id group_id,g.name group_name,
                         COALESCE(s.paid_at,s.requested_at) created_at,u.full_name payer_name,s.status,
                         COALESCE(gs.currency_code,'VND') currency_code,COALESCE(gs.decimal_scale,0) decimal_scale
                    FROM settlements s
                    JOIN groups g ON g.id=s.group_id
                    JOIN group_members gm ON gm.group_id=g.id AND gm.user_id=? AND gm.status='ACTIVE'
                    JOIN users u ON u.id=s.debtor_id
                    LEFT JOIN group_settings gs ON gs.group_id=g.id
                ) x ORDER BY created_at DESC,id DESC,kind LIMIT ? OFFSET ?
                """;
        List<ActivityItem> rows = db.query(sql, (r, n) -> new ActivityItem(
                r.getLong("id"), r.getString("title"), r.getString("kind"),
                dbToMinor(r.getBigDecimal("amount"), r.getInt("decimal_scale")),
                r.getString("currency_code"), r.getLong("group_id"), r.getString("group_name"),
                instant(r.getTimestamp("created_at")), r.getString("payer_name"), r.getString("status")),
                user.id(), user.id(), limit + 1, offset);
        boolean more = rows.size() > limit;
        return new ActivityPage(more ? List.copyOf(rows.subList(0, limit)) : rows, more ? offset + limit : null);
    }

    @Transactional
    public List<Group> groups(AuthFilter.User user) {
        ensureActiveUser(user.id());
        List<Long> ids = db.queryForList("SELECT gm.group_id FROM group_members gm JOIN groups g ON g.id=gm.group_id WHERE gm.user_id=? AND gm.status='ACTIVE' ORDER BY g.created_at DESC,g.id DESC",
                Long.class, user.id());
        List<Group> result = new ArrayList<>();
        for (long id : ids) result.add(group(id, user.id()));
        return result;
    }

    @Transactional
    public Group createGroup(AuthFilter.User user, String name, String description, String currency) {
        ensureActiveUser(user.id());
        String code = inviteCode();
        String normalizedCurrency = currency.trim().toUpperCase(Locale.ROOT);
        require(Set.of("VND", "USD", "EUR").contains(normalizedCurrency), "Currency must be VND, USD or EUR.");
        int scale = normalizedCurrency.equals("VND") ? 0 : 2;
        long id = insertAndKey("INSERT INTO groups(name,description,invite_code,owner_id,created_at,updated_at) VALUES(?,?,?,?,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)",
                clean(name, 100), blankToNull(description, 1000), code, user.id());
        db.update("INSERT INTO group_members(group_id,user_id,role,joined_at,status) VALUES(?,?,'OWNER',CURRENT_TIMESTAMP,'ACTIVE')", id, user.id());
        db.update("INSERT INTO group_settings(created_at,updated_at,auto_freeze_day,cloud_storage_sync,currency_code,decimal_scale,image_optimization_enabled,monthly_budget_limit,smart_settlement_enabled,group_id) VALUES(CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,NULL,'OFF',?,?,TRUE,NULL,TRUE,?)",
                normalizedCurrency, scale, id);
        return group(id, user.id());
    }

    @Transactional
    public Group joinGroup(AuthFilter.User user, String inviteCode) {
        ensureActiveUser(user.id());
        String code = inviteCode.trim().toUpperCase(Locale.ROOT);
        List<Long> ids = db.queryForList("SELECT id FROM groups WHERE UPPER(invite_code)=?", Long.class, code);
        if (ids.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Invite code was not found.");
        long groupId = ids.get(0);
        lockGroupRow(groupId);
        if (count("SELECT COUNT(*) FROM group_members WHERE group_id=? AND user_id=?", groupId, user.id()) == 0) {
            db.update("INSERT INTO group_members(group_id,user_id,role,joined_at,status) VALUES(?,?,'MEMBER',CURRENT_TIMESTAMP,'ACTIVE')",
                    groupId, user.id());
            notifyGroupOwner(groupId, "New member joined", profileById(user.id()).name() + " joined your group.", "MEMBER_JOINED");
        } else {
            db.update("UPDATE group_members SET status='ACTIVE' WHERE group_id=? AND user_id=?", groupId, user.id());
        }
        return group(groupId, user.id());
    }

    @Transactional
    public void addMember(long groupId, AuthFilter.User user, String email) {
        lockGroup(groupId, user.id());
        requireOwner(groupId, user.id());
        String normalized = normalizeEmail(email);
        List<Long> ids = db.queryForList("SELECT id FROM users WHERE email=?", Long.class, normalized);
        if (ids.isEmpty()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No SplitDebt account uses this email.");
        long memberId = ids.get(0);
        if (count("SELECT COUNT(*) FROM group_members WHERE group_id=? AND user_id=?", groupId, memberId) == 0) {
            db.update("INSERT INTO group_members(group_id,user_id,role,joined_at,status) VALUES(?,?,'MEMBER',CURRENT_TIMESTAMP,'ACTIVE')", groupId, memberId);
        } else {
            db.update("UPDATE group_members SET status='ACTIVE' WHERE group_id=? AND user_id=?", groupId, memberId);
        }
        insertNotification(memberId, "Added to a group", "You were added to " + groupMeta(groupId).name() + ".", "MEMBER_JOINED");
    }

    @Transactional
    public void removeMember(long groupId, AuthFilter.User user, long memberId) {
        lockGroup(groupId, user.id());
        requireOwner(groupId, user.id());
        GroupMeta meta = groupMeta(groupId);
        require(memberId != meta.ownerId(), "The group owner cannot be removed.");
        requireMember(groupId, memberId);
        long balance = balances(groupId).getOrDefault(memberId, 0L);
        require(balance == 0, "This member still has an outstanding balance and cannot be removed.");
        db.update("UPDATE group_members SET status='INACTIVE' WHERE group_id=? AND user_id=?", groupId, memberId);
        syncDebts(groupId);
    }

    // ---------------------------------------------------------------------
    // Group detail and expenses
    // ---------------------------------------------------------------------

    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public Detail detail(long groupId, AuthFilter.User user) {
        requireMember(groupId, user.id());
        Group group = group(groupId, user.id());
        List<Member> members = db.query("""
                SELECT u.id,u.email,u.full_name,u.avatar_url,gm.role,gm.status
                  FROM group_members gm JOIN users u ON u.id=gm.user_id
                 WHERE gm.group_id=? AND gm.status='ACTIVE'
                 ORDER BY CASE gm.role WHEN 'OWNER' THEN 0 ELSE 1 END,u.full_name,u.id
                """, (r, n) -> new Member(r.getLong("id"), r.getString("email"), r.getString("full_name"),
                r.getString("avatar_url"), r.getString("role"), r.getString("status")), groupId);
        List<Expense> expenses = expenses(groupId, group.decimalScale());
        List<Settlement> settlements = settlements(groupId, group.decimalScale());
        Map<Long, Long> balances = balances(groupId);
        Map<Long, Long> availableBalances = new TreeMap<>(balances);
        for (Settlement pending : settlements) {
            if ("PAID".equals(pending.status())) {
                availableBalances.merge(pending.debtorId(), pending.amount(), Long::sum);
                availableBalances.merge(pending.creditorId(), -pending.amount(), Long::sum);
            }
        }
        List<LedgerMath.Transfer> suggestions = group.smartSettlementEnabled()
                ? LedgerMath.simplify(availableBalances) : List.of();
        return new Detail(group, members, expenses, settlements, balances, suggestions);
    }

    @Transactional
    public Expense saveExpense(long groupId, Long expenseId, AuthFilter.User user,
                               LedgerController.ExpenseInput input) {
        lockGroup(groupId, user.id());
        GroupMeta meta = groupMeta(groupId);
        requireMember(groupId, input.payerId());
        require(input.totalAmount() > 0, "Expense amount must be positive.");
        if (input.categoryId() != null) {
            require(count("SELECT COUNT(*) FROM categories WHERE id=?", input.categoryId()) == 1, "Category was not found.");
        }

        String splitType = input.splitType().trim().toUpperCase(Locale.ROOT);
        require(Set.of("EQUAL", "AMOUNT", "PERCENT", "WEIGHT", "ITEM").contains(splitType), "Unsupported split type.");
        Set<Long> participantIds = new HashSet<>();
        for (LedgerController.ParticipantInput participant : input.participants()) {
            require(participantIds.add(participant.userId()), "Choose each participant only once.");
            requireMember(groupId, participant.userId());
        }

        if (expenseId != null) {
            List<Long> oldPayer = db.queryForList("SELECT payer_id FROM expenses WHERE id=? AND group_id=?", Long.class, expenseId, groupId);
            if (oldPayer.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Expense was not found.");
            require(user.id() == oldPayer.get(0) || isOwner(groupId, user.id()), "Only the payer or group owner can edit this expense.");
            deleteExpenseDetails(expenseId);
            db.update("UPDATE expenses SET category_id=?,payer_id=?,title=?,description=?,total_amount=?,expense_date=?,receipt_url=?,updated_at=CURRENT_TIMESTAMP WHERE id=? AND group_id=?",
                    input.categoryId(), input.payerId(), clean(input.title(), 200), blankToNull(input.description(), 1000),
                    minorToDb(input.totalAmount(), meta.scale()), input.expenseDate(), blankToNull(input.receiptUrl(), 2000), expenseId, groupId);
        } else {
            expenseId = insertAndKey("INSERT INTO expenses(group_id,category_id,payer_id,title,description,total_amount,expense_date,receipt_url,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)",
                    groupId, input.categoryId(), input.payerId(), clean(input.title(), 200), blankToNull(input.description(), 1000),
                    minorToDb(input.totalAmount(), meta.scale()), input.expenseDate(), blankToNull(input.receiptUrl(), 2000));
        }

        Map<Long, Long> shares = calculateShares(input, splitType);
        require(shares.values().stream().mapToLong(Long::longValue).sum() == input.totalAmount(), "Split total must equal the expense amount.");
        for (LedgerController.ParticipantInput participant : input.participants()) {
            long amount = shares.getOrDefault(participant.userId(), 0L);
            require(amount >= 0, "Participant share cannot be negative.");
            db.update("INSERT INTO expense_participants(expense_id,user_id,split_type,amount,percentage,weight) VALUES(?,?,?,?,?,?)",
                    expenseId, participant.userId(), splitType, minorToDb(amount, meta.scale()), participant.percentage(), participant.weight());
            db.update("INSERT INTO expense_shares(expense_id,user_id,amount) VALUES(?,?,?)",
                    expenseId, participant.userId(), minorToDb(amount, meta.scale()));
        }

        if (splitType.equals("ITEM")) saveItems(expenseId, groupId, meta.scale(), input);
        syncDebts(groupId);
        notifyExpenseParticipants(groupId, user.id(), participantIds, clean(input.title(), 200));
        return expenseById(expenseId, meta.scale());
    }

    @Transactional
    public void deleteExpense(long groupId, long expenseId, AuthFilter.User user) {
        lockGroup(groupId, user.id());
        List<Long> payer = db.queryForList("SELECT payer_id FROM expenses WHERE id=? AND group_id=?", Long.class, expenseId, groupId);
        if (payer.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Expense was not found.");
        require(user.id() == payer.get(0) || isOwner(groupId, user.id()), "Only the payer or group owner can delete this expense.");
        deleteExpenseDetails(expenseId);
        db.update("DELETE FROM expenses WHERE id=? AND group_id=?", expenseId, groupId);
        syncDebts(groupId);
    }

    private Map<Long, Long> calculateShares(LedgerController.ExpenseInput input, String splitType) {
        List<Long> ids = input.participants().stream().map(LedgerController.ParticipantInput::userId).toList();
        return switch (splitType) {
            case "EQUAL" -> LedgerMath.split(input.totalAmount(), ids);
            case "AMOUNT" -> {
                Map<Long, Long> result = new TreeMap<>();
                long sum = 0;
                for (var p : input.participants()) {
                    require(p.amount() != null && p.amount() >= 0, "Enter an amount for every participant.");
                    result.put(p.userId(), p.amount());
                    sum = Math.addExact(sum, p.amount());
                }
                require(sum == input.totalAmount(), "Participant amounts must add up to the expense total.");
                yield result;
            }
            case "PERCENT" -> {
                Map<Long, BigDecimal> ratios = new TreeMap<>();
                BigDecimal sum = BigDecimal.ZERO;
                for (var p : input.participants()) {
                    require(p.percentage() != null && p.percentage().compareTo(BigDecimal.ZERO) > 0,
                            "Enter a positive percentage for every participant.");
                    ratios.put(p.userId(), p.percentage());
                    sum = sum.add(p.percentage());
                }
                require(sum.compareTo(new BigDecimal("100")) == 0, "Percentages must add up to 100%.");
                yield LedgerMath.splitByRatios(input.totalAmount(), ratios);
            }
            case "WEIGHT" -> {
                Map<Long, BigDecimal> ratios = new TreeMap<>();
                for (var p : input.participants()) {
                    require(p.weight() != null && p.weight().compareTo(BigDecimal.ZERO) > 0,
                            "Enter a positive weight for every participant.");
                    ratios.put(p.userId(), p.weight());
                }
                yield LedgerMath.splitByRatios(input.totalAmount(), ratios);
            }
            case "ITEM" -> calculateItemShares(input);
            default -> throw new IllegalStateException("Unexpected split type.");
        };
    }

    private Map<Long, Long> calculateItemShares(LedgerController.ExpenseInput input) {
        require(input.items() != null && !input.items().isEmpty(), "Add at least one item for item-based splitting.");
        Set<Long> allowed = new HashSet<>(input.participants().stream().map(LedgerController.ParticipantInput::userId).toList());
        Map<Long, Long> result = new TreeMap<>();
        allowed.forEach(id -> result.put(id, 0L));
        long itemTotal = 0;
        for (var item : input.items()) {
            itemTotal = Math.addExact(itemTotal, item.totalPrice());
            require(item.participantIds() != null && !item.participantIds().isEmpty(), "Every item needs at least one participant.");
            require(new HashSet<>(item.participantIds()).size() == item.participantIds().size(), "An item cannot contain the same participant twice.");
            for (long id : item.participantIds()) require(allowed.contains(id), "Item participant must also be an expense participant.");
            Map<Long, Long> itemShares = LedgerMath.split(item.totalPrice(), item.participantIds());
            itemShares.forEach((id, amount) -> result.merge(id, amount, Long::sum));
        }
        require(itemTotal == input.totalAmount(), "Item totals must add up to the expense total.");
        return result;
    }

    private void saveItems(long expenseId, long groupId, int scale, LedgerController.ExpenseInput input) {
        if (input.items() == null) return;
        for (var item : input.items()) {
            for (long id : item.participantIds()) requireMember(groupId, id);
            long itemId = insertAndKey("INSERT INTO expense_items(expense_id,item_name,quantity,unit_price,total_price) VALUES(?,?,?,?,?)",
                    expenseId, clean(item.itemName(), 200), item.quantity(), minorToDb(item.unitPrice(), scale), minorToDb(item.totalPrice(), scale));
            Map<Long, Long> itemShares = LedgerMath.split(item.totalPrice(), item.participantIds());
            itemShares.forEach((id, share) -> db.update("INSERT INTO item_participants(item_id,user_id,share_amount) VALUES(?,?,?)",
                    itemId, id, minorToDb(share, scale)));
        }
    }

    private void deleteExpenseDetails(long expenseId) {
        db.update("DELETE FROM item_participants WHERE item_id IN (SELECT id FROM expense_items WHERE expense_id=?)", expenseId);
        db.update("DELETE FROM expense_items WHERE expense_id=?", expenseId);
        db.update("DELETE FROM expense_shares WHERE expense_id=?", expenseId);
        db.update("DELETE FROM expense_participants WHERE expense_id=?", expenseId);
    }

    // ---------------------------------------------------------------------
    // Balances, debts and settlements
    // ---------------------------------------------------------------------

    public Map<Long, Long> balances(long groupId) {
        GroupMeta meta = groupMeta(groupId);
        Map<Long, Long> result = new TreeMap<>();
        db.queryForList("SELECT user_id FROM group_members WHERE group_id=? AND status='ACTIVE'", Long.class, groupId)
                .forEach(id -> result.put(id, 0L));
        db.query("SELECT payer_id,total_amount FROM expenses WHERE group_id=?", r -> {
            result.merge(r.getLong(1), dbToMinor(r.getBigDecimal(2), meta.scale()), Long::sum);
        }, groupId);
        db.query("SELECT ep.user_id,ep.amount FROM expense_participants ep JOIN expenses e ON e.id=ep.expense_id WHERE e.group_id=?", r -> {
            result.merge(r.getLong(1), -dbToMinor(r.getBigDecimal(2), meta.scale()), Long::sum);
        }, groupId);
        db.query("SELECT debtor_id,creditor_id,amount FROM settlements WHERE group_id=? AND status='CONFIRMED'", r -> {
            long amount = dbToMinor(r.getBigDecimal(3), meta.scale());
            result.merge(r.getLong(1), amount, Long::sum);
            result.merge(r.getLong(2), -amount, Long::sum);
        }, groupId);
        long total = result.values().stream().mapToLong(Long::longValue).sum();
        if (total != 0) throw new IllegalStateException("Group ledger is not balanced: " + total);
        return result;
    }

    private void syncDebts(long groupId) {
        GroupMeta meta = groupMeta(groupId);
        db.update("DELETE FROM debts WHERE group_id=?", groupId);
        for (LedgerMath.Transfer transfer : LedgerMath.simplify(balances(groupId))) {
            db.update("INSERT INTO debts(group_id,debtor_id,creditor_id,amount,source_type,status,created_at,updated_at) VALUES(?,?,?,?,?,'OPEN',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)",
                    groupId, transfer.fromId(), transfer.toId(), minorToDb(transfer.amount(), meta.scale()), "CALCULATED");
        }
    }

    @Transactional
    public Settlement recordSettlement(long groupId, AuthFilter.User user, long creditorId, long amount, String paymentMethod) {
        lockGroup(groupId, user.id());
        requireMember(groupId, creditorId);
        require(creditorId != user.id(), "Choose another member as the recipient.");
        Map<Long, Long> balances = balances(groupId);
        long debtorBalance = balances.getOrDefault(user.id(), 0L);
        long creditorBalance = balances.getOrDefault(creditorId, 0L);
        require(debtorBalance < 0 && creditorBalance > 0, "This payment does not match the current outstanding balances.");
        GroupMeta meta = groupMeta(groupId);
        BigDecimal pendingOutDb = db.queryForObject(
                "SELECT COALESCE(SUM(amount),0) FROM settlements WHERE group_id=? AND debtor_id=? AND status='PAID'",
                BigDecimal.class, groupId, user.id());
        BigDecimal pendingInDb = db.queryForObject(
                "SELECT COALESCE(SUM(amount),0) FROM settlements WHERE group_id=? AND creditor_id=? AND status='PAID'",
                BigDecimal.class, groupId, creditorId);
        long pendingOut = dbToMinor(pendingOutDb == null ? BigDecimal.ZERO : pendingOutDb, meta.scale());
        long pendingIn = dbToMinor(pendingInDb == null ? BigDecimal.ZERO : pendingInDb, meta.scale());
        long debtorRemaining = Math.max(0L, -debtorBalance - pendingOut);
        long creditorRemaining = Math.max(0L, creditorBalance - pendingIn);
        long remaining = Math.min(debtorRemaining, creditorRemaining);
        require(amount > 0 && amount <= remaining, "Payment exceeds the outstanding balance or is already waiting for confirmation.");
        long id = insertAndKey("INSERT INTO settlements(group_id,debtor_id,creditor_id,amount,status,payment_method,requested_at,paid_at,confirmed_at) VALUES(?,?,?,?,'PAID',?,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,NULL)",
                groupId, user.id(), creditorId, minorToDb(amount, meta.scale()), blankToNull(paymentMethod, 50));
        Profile debtor = profileById(user.id());
        insertNotification(creditorId, "Payment waiting for confirmation",
                debtor.name() + " marked a payment as paid. Confirm it after you receive the money.", "SETTLEMENT_PAID");
        return settlementById(id, meta.scale());
    }

    @Transactional
    public Settlement confirmSettlement(long settlementId, AuthFilter.User user) {
        SettlementRow row = settlementRow(settlementId);
        lockGroup(row.groupId(), user.id());
        require(row.creditorId() == user.id(), "Only the recipient can confirm this payment.");
        require("PAID".equals(row.status()), "Only a paid settlement can be confirmed.");
        db.update("UPDATE settlements SET status='CONFIRMED',confirmed_at=CURRENT_TIMESTAMP WHERE id=? AND status='PAID'", settlementId);
        syncDebts(row.groupId());
        insertNotification(row.debtorId(), "Payment confirmed",
                profileById(user.id()).name() + " confirmed receiving your payment.", "SETTLEMENT_CONFIRMED");
        return settlementById(settlementId, groupMeta(row.groupId()).scale());
    }

    @Transactional
    public Settlement cancelSettlement(long settlementId, AuthFilter.User user) {
        SettlementRow row = settlementRow(settlementId);
        lockGroup(row.groupId(), user.id());
        require(row.debtorId() == user.id() || isOwner(row.groupId(), user.id()), "Only the payer or group owner can cancel this settlement.");
        require(Set.of("PENDING", "PAID").contains(row.status()), "This settlement can no longer be cancelled.");
        db.update("UPDATE settlements SET status='CANCELLED' WHERE id=?", settlementId);
        insertNotification(row.creditorId(), "Payment record cancelled", "A pending payment record was cancelled.", "SETTLEMENT_CANCELLED");
        return settlementById(settlementId, groupMeta(row.groupId()).scale());
    }

    private SettlementRow settlementRow(long id) {
        List<SettlementRow> rows = db.query("SELECT * FROM settlements WHERE id=?", (r, n) -> {
            GroupMeta meta = groupMeta(r.getLong("group_id"));
            return new SettlementRow(r.getLong("id"), r.getLong("group_id"), r.getLong("debtor_id"), r.getLong("creditor_id"),
                    dbToMinor(r.getBigDecimal("amount"), meta.scale()), r.getString("status"), r.getString("payment_method"),
                    instant(r.getTimestamp("requested_at")), instant(r.getTimestamp("paid_at")), instant(r.getTimestamp("confirmed_at")));
        }, id);
        if (rows.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Settlement was not found.");
        return rows.get(0);
    }

    // ---------------------------------------------------------------------
    // Categories, notifications and statistics
    // ---------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<Map<String, Object>> categories() {
        return db.query("SELECT id,name,icon FROM categories ORDER BY id", (r, n) -> {
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("id", r.getLong("id"));
            out.put("name", r.getString("name"));
            out.put("icon", r.getString("icon"));
            return out;
        });
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> notifications(AuthFilter.User user, int limit) {
        require(limit >= 1 && limit <= 100, "Notification limit must be between 1 and 100.");
        return db.query("SELECT id,title,content,type,is_read,created_at FROM notifications WHERE user_id=? ORDER BY created_at DESC,id DESC LIMIT ?",
                (r, n) -> {
                    Map<String, Object> out = new LinkedHashMap<>();
                    out.put("id", r.getLong("id"));
                    out.put("title", r.getString("title"));
                    out.put("content", r.getString("content"));
                    out.put("type", r.getString("type"));
                    out.put("isRead", r.getBoolean("is_read"));
                    out.put("createdAt", instant(r.getTimestamp("created_at")));
                    return out;
                }, user.id(), limit);
    }

    @Transactional
    public void markNotificationRead(AuthFilter.User user, long id) {
        int changed = db.update("UPDATE notifications SET is_read=TRUE WHERE id=? AND user_id=?", id, user.id());
        if (changed == 0) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Notification was not found.");
    }

    @Transactional(readOnly = true)
    public Map<String, Object> statistics(long groupId, AuthFilter.User user, String range) {
        requireMember(groupId, user.id());
        GroupMeta meta = groupMeta(groupId);
        String normalized = range == null ? "MONTH" : range.toUpperCase(Locale.ROOT);
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        LocalDate from = switch (normalized) {
            case "WEEK" -> today.minusDays(6);
            case "MONTH" -> today.with(TemporalAdjusters.firstDayOfMonth());
            case "ALL" -> LocalDate.of(1970, 1, 1);
            default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Range must be WEEK, MONTH or ALL.");
        };
        BigDecimal totalDb = db.queryForObject("SELECT COALESCE(SUM(total_amount),0) FROM expenses WHERE group_id=? AND expense_date BETWEEN ? AND ?",
                BigDecimal.class, groupId, from, today);
        List<Map<String, Object>> byCategory = db.query("""
                SELECT COALESCE(c.name,'Other') label,COALESCE(SUM(e.total_amount),0) amount
                  FROM expenses e LEFT JOIN categories c ON c.id=e.category_id
                 WHERE e.group_id=? AND e.expense_date BETWEEN ? AND ?
                 GROUP BY COALESCE(c.name,'Other') ORDER BY amount DESC,label
                """, (r, n) -> Map.<String, Object>of("label", r.getString("label"),
                "amount", dbToMinor(r.getBigDecimal("amount"), meta.scale())), groupId, from, today);
        List<Map<String, Object>> byPayer = db.query("""
                SELECT u.id,u.full_name label,COALESCE(SUM(e.total_amount),0) amount
                  FROM expenses e JOIN users u ON u.id=e.payer_id
                 WHERE e.group_id=? AND e.expense_date BETWEEN ? AND ?
                 GROUP BY u.id,u.full_name ORDER BY amount DESC,u.full_name
                """, (r, n) -> Map.<String, Object>of("userId", r.getLong("id"), "label", r.getString("label"),
                "amount", dbToMinor(r.getBigDecimal("amount"), meta.scale())), groupId, from, today);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("range", normalized);
        out.put("from", from.toString());
        out.put("to", today.toString());
        out.put("currency", meta.currency());
        out.put("totalExpense", dbToMinor(totalDb == null ? BigDecimal.ZERO : totalDb, meta.scale()));
        out.put("byCategory", byCategory);
        out.put("byPayer", byPayer);
        return out;
    }

    // ---------------------------------------------------------------------
    // Mappers and small helpers
    // ---------------------------------------------------------------------

    private Group group(long id, long userId) {
        GroupMeta meta = groupMeta(id);
        Map<Long, Long> balances = balances(id);
        long total = db.query("SELECT total_amount FROM expenses WHERE group_id=?", r -> {
            long sum = 0;
            while (r.next()) sum = Math.addExact(sum, dbToMinor(r.getBigDecimal(1), meta.scale()));
            return sum;
        }, id);
        int memberCount = count("SELECT COUNT(*) FROM group_members WHERE group_id=? AND status='ACTIVE'", id);
        return new Group(id, meta.name(), meta.description(), meta.inviteCode(), meta.ownerId(), meta.createdAt(),
                memberCount, balances.getOrDefault(userId, 0L), total, meta.currency(), meta.scale(), meta.smartSettlementEnabled());
    }

    private GroupMeta groupMeta(long id) {
        if (count("SELECT COUNT(*) FROM groups WHERE id=?", id) == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Group was not found.");
        }
        return db.queryForObject("""
                SELECT g.id,g.name,g.description,g.invite_code,g.owner_id,g.created_at,
                       COALESCE(gs.currency_code,'VND') currency_code,
                       COALESCE(gs.decimal_scale,0) decimal_scale,
                       COALESCE(gs.smart_settlement_enabled,TRUE) smart_settlement_enabled
                  FROM groups g LEFT JOIN group_settings gs ON gs.group_id=g.id WHERE g.id=?
                """, (r, n) -> new GroupMeta(r.getLong("id"), r.getString("name"), r.getString("description"),
                r.getString("invite_code"), r.getLong("owner_id"), instant(r.getTimestamp("created_at")),
                r.getString("currency_code"), r.getInt("decimal_scale"), r.getBoolean("smart_settlement_enabled")), id);
    }

    private void ensureGroupSettings(long groupId, String currency) {
        if (count("SELECT COUNT(*) FROM group_settings WHERE group_id=?", groupId) == 0) {
            String normalized = Set.of("VND", "USD", "EUR").contains(currency) ? currency : "VND";
            int scale = normalized.equals("VND") ? 0 : 2;
            db.update("INSERT INTO group_settings(created_at,updated_at,auto_freeze_day,cloud_storage_sync,currency_code,decimal_scale,image_optimization_enabled,monthly_budget_limit,smart_settlement_enabled,group_id) VALUES(CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,NULL,'OFF',?,?,TRUE,NULL,TRUE,?)",
                    normalized, scale, groupId);
        }
    }

    private List<Expense> expenses(long groupId, int scale) {
        return db.query("""
                SELECT e.*,c.name category_name FROM expenses e LEFT JOIN categories c ON c.id=e.category_id
                 WHERE e.group_id=? ORDER BY e.expense_date DESC,e.created_at DESC,e.id DESC
                """, (r, n) -> expenseFromRow(r.getLong("id"), r.getString("title"), r.getString("description"),
                dbToMinor(r.getBigDecimal("total_amount"), scale), nullableLong(r, "category_id"), r.getString("category_name"),
                r.getLong("payer_id"), r.getDate("expense_date").toLocalDate().toString(), r.getString("receipt_url"),
                instant(r.getTimestamp("created_at")), instant(r.getTimestamp("updated_at")), scale), groupId);
    }

    private Expense expenseById(long expenseId, int scale) {
        return db.queryForObject("""
                SELECT e.*,c.name category_name FROM expenses e LEFT JOIN categories c ON c.id=e.category_id WHERE e.id=?
                """, (r, n) -> expenseFromRow(r.getLong("id"), r.getString("title"), r.getString("description"),
                dbToMinor(r.getBigDecimal("total_amount"), scale), nullableLong(r, "category_id"), r.getString("category_name"),
                r.getLong("payer_id"), r.getDate("expense_date").toLocalDate().toString(), r.getString("receipt_url"),
                instant(r.getTimestamp("created_at")), instant(r.getTimestamp("updated_at")), scale), expenseId);
    }

    private Expense expenseFromRow(long id, String title, String description, long amount, Long categoryId,
                                    String categoryName, long payerId, String expenseDate, String receiptUrl,
                                    String createdAt, String updatedAt, int scale) {
        List<Share> shares = db.query("SELECT user_id,split_type,amount,percentage,weight FROM expense_participants WHERE expense_id=? ORDER BY user_id",
                (r, n) -> new Share(r.getLong("user_id"), r.getString("split_type"), dbToMinor(r.getBigDecimal("amount"), scale),
                        r.getBigDecimal("percentage"), r.getBigDecimal("weight")), id);
        List<ExpenseItem> items = db.query("SELECT id,item_name,quantity,unit_price,total_price FROM expense_items WHERE expense_id=? ORDER BY id",
                (r, n) -> {
                    long itemId = r.getLong("id");
                    List<ItemShare> itemShares = db.query("SELECT user_id,share_amount FROM item_participants WHERE item_id=? ORDER BY user_id",
                            (x, k) -> new ItemShare(x.getLong("user_id"), dbToMinor(x.getBigDecimal("share_amount"), scale)), itemId);
                    return new ExpenseItem(itemId, r.getString("item_name"), r.getBigDecimal("quantity"),
                            dbToMinor(r.getBigDecimal("unit_price"), scale), dbToMinor(r.getBigDecimal("total_price"), scale), itemShares);
                }, id);
        return new Expense(id, title, description, amount, categoryId, categoryName, payerId, expenseDate,
                receiptUrl, createdAt, updatedAt, shares, items);
    }

    private List<Settlement> settlements(long groupId, int scale) {
        return db.query("SELECT * FROM settlements WHERE group_id=? ORDER BY COALESCE(confirmed_at,paid_at,requested_at) DESC,id DESC",
                (r, n) -> new Settlement(r.getLong("id"), r.getLong("debtor_id"), r.getLong("creditor_id"),
                        dbToMinor(r.getBigDecimal("amount"), scale), r.getString("status"), r.getString("payment_method"),
                        instant(r.getTimestamp("requested_at")), instant(r.getTimestamp("paid_at")), instant(r.getTimestamp("confirmed_at"))), groupId);
    }

    private Settlement settlementById(long id, int scale) {
        return db.queryForObject("SELECT * FROM settlements WHERE id=?", (r, n) -> new Settlement(
                r.getLong("id"), r.getLong("debtor_id"), r.getLong("creditor_id"), dbToMinor(r.getBigDecimal("amount"), scale),
                r.getString("status"), r.getString("payment_method"), instant(r.getTimestamp("requested_at")),
                instant(r.getTimestamp("paid_at")), instant(r.getTimestamp("confirmed_at"))), id);
    }

    private void notifyExpenseParticipants(long groupId, long actorId, Set<Long> participants, String title) {
        String groupName = groupMeta(groupId).name();
        for (long id : participants) {
            if (id != actorId && notificationEnabled(id, "notify_on_new_expense")) {
                insertNotification(id, "New expense in " + groupName, title + " was added.", "NEW_EXPENSE");
            }
        }
    }

    private void notifyGroupOwner(long groupId, String title, String content, String type) {
        insertNotification(groupMeta(groupId).ownerId(), title, content, type);
    }

    private boolean notificationEnabled(long userId, String column) {
        ensureUserSettings(userId);
        return Boolean.TRUE.equals(db.queryForObject("SELECT " + column + " FROM user_settings WHERE user_id=?", Boolean.class, userId));
    }

    private void insertNotification(long userId, String title, String content, String type) {
        db.update("INSERT INTO notifications(user_id,title,content,type,is_read,created_at) VALUES(?,?,?,?,FALSE,CURRENT_TIMESTAMP)",
                userId, clean(title, 200), content, type);
    }

    private void lockGroup(long groupId, long userId) {
        requireMember(groupId, userId);
        lockGroupRow(groupId);
    }

    private void lockGroupRow(long groupId) {
        List<Long> ids = db.queryForList("SELECT id FROM groups WHERE id=? FOR UPDATE", Long.class, groupId);
        if (ids.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Group was not found.");
    }

    private void requireMember(long groupId, long userId) {
        if (count("SELECT COUNT(*) FROM group_members WHERE group_id=? AND user_id=? AND status='ACTIVE'", groupId, userId) == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Group was not found or you are not an active member.");
        }
    }

    private boolean isOwner(long groupId, long userId) {
        return count("SELECT COUNT(*) FROM groups WHERE id=? AND owner_id=?", groupId, userId) == 1;
    }

    private void requireOwner(long groupId, long userId) {
        if (!isOwner(groupId, userId)) throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only the group owner can do this.");
    }

    private long insertAndKey(String sql, Object... params) {
        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        db.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(sql, new String[]{"id"});
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        if (key == null) throw new IllegalStateException("Database did not return a generated id.");
        return key.longValue();
    }

    private int count(String sql, Object... args) {
        Integer value = db.queryForObject(sql, Integer.class, args);
        return value == null ? 0 : value;
    }

    private static String inviteCode() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 10).toUpperCase(Locale.ROOT);
    }

    private static BigDecimal minorToDb(long amount, int scale) {
        return BigDecimal.valueOf(amount, scale);
    }

    private static long dbToMinor(BigDecimal amount, int scale) {
        if (amount == null) return 0L;
        return amount.setScale(scale, RoundingMode.HALF_UP).movePointRight(scale).longValueExact();
    }

    private static String normalizeEmail(String email) {
        String value = Objects.requireNonNullElse(email, "").trim().toLowerCase(Locale.ROOT);
        require(value.contains("@") && value.length() <= 255, "Enter a valid email address.");
        return value;
    }

    private static String clean(String value, int max) {
        String out = Objects.requireNonNullElse(value, "").trim();
        require(!out.isEmpty(), "A required value is missing.");
        require(out.length() <= max, "A value is too long.");
        return out;
    }

    private static String blankToNull(String value, int max) {
        if (value == null || value.trim().isEmpty()) return null;
        String out = value.trim();
        require(out.length() <= max, "A value is too long.");
        return out;
    }

    private static boolean valueOr(Boolean value, boolean fallback) {
        return value == null ? fallback : value;
    }

    private static String valueOrText(String value, String fallback, int max) {
        if (value == null) return fallback;
        return clean(value, max);
    }

    private static String instant(Timestamp value) {
        return value == null ? null : value.toInstant().toString();
    }

    private static Long nullableLong(java.sql.ResultSet r, String column) throws java.sql.SQLException {
        Object value = r.getObject(column);
        return value == null ? null : ((Number) value).longValue();
    }

    static void require(boolean value, String message) {
        if (!value) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }
}
