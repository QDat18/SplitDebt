package com.splitdebt.api.ledger;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class LedgerController {
    private final LedgerService service;

    public LedgerController(LedgerService service) {
        this.service = service;
    }

    public record GroupInput(
            @NotBlank @Size(max = 100) String name,
            @Size(max = 500) String description,
            @NotBlank @Size(max = 10) String currency) {}

    public record JoinGroupInput(@NotBlank @Size(max = 64) String inviteCode) {}
    public record MemberInput(
            @Size(max = 255) String identifier,
            @Size(max = 255) String email,
            @Size(max = 30) String phone) {
        String value() {
            if (identifier != null && !identifier.isBlank()) return identifier;
            if (email != null && !email.isBlank()) return email;
            if (phone != null && !phone.isBlank()) return phone;
            return "";
        }
    }
    public record ProfileInput(@NotBlank @Size(max = 100) String fullName, @Size(max = 20) String phone, String avatarUrl) {}

    public record ParticipantInput(
            @NotNull @Positive Long userId,
            Long amount,
            BigDecimal percentage,
            BigDecimal weight) {}

    public record ItemInput(
            @NotBlank @Size(max = 200) String itemName,
            @NotNull @Positive BigDecimal quantity,
            @NotNull @Min(0) Long unitPrice,
            @NotNull @Positive Long totalPrice,
            @NotEmpty List<@Positive Long> participantIds) {}

    public record ExpenseInput(
            @NotBlank @Size(max = 200) String title,
            @Size(max = 1000) String description,
            @NotNull @Min(1) @Max(1_000_000_000_000L) Long totalAmount,
            Long categoryId,
            @NotNull @Positive Long payerId,
            @NotNull LocalDate expenseDate,
            String receiptUrl,
            @NotBlank String splitType,
            @NotEmpty @Size(max = 100) List<@Valid ParticipantInput> participants,
            List<@Valid ItemInput> items) {}

    public record SettlementInput(
            @NotNull @Positive Long creditorId,
            @NotNull @Min(1) @Max(1_000_000_000_000L) Long amount,
            @Size(max = 50) String paymentMethod) {}

    public record UserSettingsInput(
            Boolean biometricsEnabled,
            String language,
            Boolean notifyOnDebtReminder,
            Boolean notifyOnNewExpense,
            Boolean notifyOnSettlement,
            String theme) {}

    public record GroupSettingsInput(
            Integer autoFreezeDay,
            String cloudStorageSync,
            String currencyCode,
            Integer decimalScale,
            Boolean imageOptimizationEnabled,
            Long monthlyBudgetLimit,
            Boolean smartSettlementEnabled) {}

    @GetMapping("/overview")
    public Object overview(@RequestAttribute("user") AuthFilter.User user) {
        return service.overview(user);
    }

    @GetMapping("/activity")
    public Object activity(@RequestAttribute("user") AuthFilter.User user,
                           @RequestParam(defaultValue = "30") int limit,
                           @RequestParam(defaultValue = "0") int offset) {
        return service.activity(user, limit, offset);
    }

    @GetMapping("/me")
    public Object me(@RequestAttribute("user") AuthFilter.User user) {
        return service.profile(user);
    }

    @PatchMapping("/me")
    public Object updateProfile(@RequestAttribute("user") AuthFilter.User user,
                                @Valid @RequestBody ProfileInput input) {
        return service.updateProfile(user, input.fullName(), input.phone(), input.avatarUrl());
    }

    @GetMapping("/me/settings")
    public Object userSettings(@RequestAttribute("user") AuthFilter.User user) {
        return service.userSettings(user);
    }

    @PatchMapping("/me/settings")
    public Object updateUserSettings(@RequestAttribute("user") AuthFilter.User user,
                                     @RequestBody UserSettingsInput input) {
        return service.updateUserSettings(user, input);
    }

    @GetMapping("/categories")
    public Object categories(@RequestAttribute("user") AuthFilter.User user) {
        return service.categories();
    }

    @GetMapping("/notifications")
    public Object notifications(@RequestAttribute("user") AuthFilter.User user,
                                @RequestParam(defaultValue = "50") int limit) {
        return service.notifications(user, limit);
    }

    @PostMapping("/notifications/{id}/read")
    public Object readNotification(@PathVariable long id, @RequestAttribute("user") AuthFilter.User user) {
        service.markNotificationRead(user, id);
        return Map.of("ok", true);
    }

    @PostMapping("/notifications/read-all")
    public Object readAllNotifications(@RequestAttribute("user") AuthFilter.User user) {
        return Map.of("ok", true, "updated", service.markAllNotificationsRead(user));
    }

    @GetMapping("/groups")
    public Object groups(@RequestAttribute("user") AuthFilter.User user) {
        return service.groups(user);
    }

    @PostMapping("/groups")
    public Object createGroup(@RequestAttribute("user") AuthFilter.User user,
                              @Valid @RequestBody GroupInput input) {
        return service.createGroup(user, input.name(), input.description(), input.currency());
    }

    @PostMapping("/groups/join")
    public Object joinGroup(@RequestAttribute("user") AuthFilter.User user,
                            @Valid @RequestBody JoinGroupInput input) {
        return service.joinGroup(user, input.inviteCode());
    }

    @GetMapping("/groups/{id}")
    public Object detail(@PathVariable long id, @RequestAttribute("user") AuthFilter.User user) {
        return service.detail(id, user);
    }

    @PostMapping("/groups/{id}/members")
    public Object addMember(@PathVariable long id,
                            @RequestAttribute("user") AuthFilter.User user,
                            @Valid @RequestBody MemberInput input) {
        service.addMember(id, user, input.value());
        return Map.of("ok", true);
    }

    @DeleteMapping("/groups/{id}/members/{userId}")
    public Object removeMember(@PathVariable long id,
                               @PathVariable long userId,
                               @RequestAttribute("user") AuthFilter.User user) {
        service.removeMember(id, user, userId);
        return Map.of("ok", true);
    }

    @GetMapping("/groups/{id}/settings")
    public Object groupSettings(@PathVariable long id, @RequestAttribute("user") AuthFilter.User user) {
        return service.groupSettings(id, user);
    }

    @PatchMapping("/groups/{id}/settings")
    public Object updateGroupSettings(@PathVariable long id,
                                      @RequestAttribute("user") AuthFilter.User user,
                                      @RequestBody GroupSettingsInput input) {
        return service.updateGroupSettings(id, user, input);
    }

    @PostMapping("/groups/{id}/expenses")
    public Object addExpense(@PathVariable long id,
                             @RequestAttribute("user") AuthFilter.User user,
                             @Valid @RequestBody ExpenseInput input) {
        return service.saveExpense(id, null, user, input);
    }

    @PutMapping("/groups/{id}/expenses/{expenseId}")
    public Object editExpense(@PathVariable long id,
                              @PathVariable long expenseId,
                              @RequestAttribute("user") AuthFilter.User user,
                              @Valid @RequestBody ExpenseInput input) {
        return service.saveExpense(id, expenseId, user, input);
    }

    @DeleteMapping("/groups/{id}/expenses/{expenseId}")
    public Object deleteExpense(@PathVariable long id,
                                @PathVariable long expenseId,
                                @RequestAttribute("user") AuthFilter.User user) {
        service.deleteExpense(id, expenseId, user);
        return Map.of("ok", true);
    }

    @GetMapping("/groups/{id}/statistics")
    public Object statistics(@PathVariable long id,
                             @RequestAttribute("user") AuthFilter.User user,
                             @RequestParam(defaultValue = "MONTH") String range) {
        return service.statistics(id, user, range);
    }

    @PostMapping("/groups/{id}/settlements")
    public Object recordSettlement(@PathVariable long id,
                                   @RequestAttribute("user") AuthFilter.User user,
                                   @Valid @RequestBody SettlementInput input) {
        return service.recordSettlement(id, user, input.creditorId(), input.amount(), input.paymentMethod());
    }

    @PostMapping("/settlements/{id}/confirm")
    public Object confirmSettlement(@PathVariable long id, @RequestAttribute("user") AuthFilter.User user) {
        return service.confirmSettlement(id, user);
    }

    @PostMapping("/settlements/{id}/cancel")
    public Object cancelSettlement(@PathVariable long id, @RequestAttribute("user") AuthFilter.User user) {
        return service.cancelSettlement(id, user);
    }
}
