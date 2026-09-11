package com.splitdebt.api.service.impl;

import com.splitdebt.api.dto.request.*;
import com.splitdebt.api.dto.response.*;
import com.splitdebt.api.entity.*;
import com.splitdebt.api.entity.enums.SettlementStatus;
import com.splitdebt.api.entity.enums.SplitType;
import com.splitdebt.api.repository.*;
import com.splitdebt.api.service.ExpenseService;
import com.splitdebt.api.service.SettingService;
import com.splitdebt.api.service.SettlementEngineService;
import com.splitdebt.api.util.MoneySplitCalculator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ExpenseServiceImpl implements ExpenseService {

    private final ExpenseRepository expenseRepository;
    private final ExpenseParticipantRepository expenseParticipantRepository;
    private final ExpenseItemRepository expenseItemRepository;
    private final ItemParticipantRepository itemParticipantRepository;
    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final SettlementRepository settlementRepository;
    private final SettlementEngineService settlementEngineService;
    private final SettingService settingService;

    @Override
    @Transactional
    public ExpenseResponse createExpense(CreateExpenseRequest request) {
        Group group = groupRepository.findById(request.getGroupId())
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay nhom voi ID: " + request.getGroupId()));
        User payer = userRepository.findById(request.getPayerId())
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay nguoi thanh toan voi ID: " + request.getPayerId()));

        Category category = null;
        if (request.getCategoryId() != null) {
            category = categoryRepository.findById(request.getCategoryId()).orElse(null);
        }

        if (request.getTotalAmount() == null || request.getTotalAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Tong so tien chi tieu phai lon hon 0");
        }

        Expense expense = Expense.builder()
                .group(group)
                .category(category)
                .payer(payer)
                .title(request.getTitle())
                .description(request.getDescription())
                .totalAmount(request.getTotalAmount())
                .expenseDate(request.getExpenseDate())
                .receiptUrl(request.getReceiptUrl())
                .build();

        expense = expenseRepository.save(expense);

        List<ExpenseParticipant> savedParticipants = processParticipants(expense, request);
        List<ExpenseItem> savedItems = processItems(expense, request);

        // Recalculate group net debts automatically
        settlementEngineService.recalculateGroupDebts(group.getId());

        return mapToExpenseResponse(expense, savedParticipants, savedItems);
    }

    private List<ExpenseParticipant> processParticipants(Expense expense, CreateExpenseRequest request) {
        List<ExpenseParticipantRequest> participantRequests = request.getParticipants();
        if (participantRequests == null || participantRequests.isEmpty()) {
            throw new IllegalArgumentException("Danh sach nguoi tham gia chi tieu khong duoc de rong");
        }

        SplitType splitType = request.getSplitType();
        BigDecimal totalAmount = expense.getTotalAmount();
        List<ExpenseParticipant> participants = new ArrayList<>();
        int scale = settingService.getDecimalScaleByGroupId(expense.getGroup().getId());

        if (splitType == SplitType.EQUAL) {
            List<BigDecimal> calculatedAmounts = MoneySplitCalculator.calculateEqualSplit(totalAmount, participantRequests.size(), scale);
            for (int i = 0; i < participantRequests.size(); i++) {
                ExpenseParticipantRequest pr = participantRequests.get(i);
                User user = userRepository.findById(pr.getUserId())
                        .orElseThrow(() -> new IllegalArgumentException("Nguoi dung khong hop le: " + pr.getUserId()));

                participants.add(ExpenseParticipant.builder()
                        .expense(expense)
                        .user(user)
                        .splitType(SplitType.EQUAL)
                        .amount(calculatedAmounts.get(i))
                        .build());
            }
        } else if (splitType == SplitType.AMOUNT) {
            List<BigDecimal> specifiedAmounts = participantRequests.stream()
                    .map(ExpenseParticipantRequest::getAmount)
                    .collect(Collectors.toList());
            MoneySplitCalculator.validateAmountSplit(totalAmount, specifiedAmounts, scale);

            for (ExpenseParticipantRequest pr : participantRequests) {
                User user = userRepository.findById(pr.getUserId())
                        .orElseThrow(() -> new IllegalArgumentException("Nguoi dung khong hop le: " + pr.getUserId()));

                participants.add(ExpenseParticipant.builder()
                        .expense(expense)
                        .user(user)
                        .splitType(SplitType.AMOUNT)
                        .amount(pr.getAmount())
                        .build());
            }
        } else if (splitType == SplitType.PERCENT) {
            List<BigDecimal> percentages = participantRequests.stream()
                    .map(ExpenseParticipantRequest::getPercentage)
                    .collect(Collectors.toList());
            List<BigDecimal> calculatedAmounts = MoneySplitCalculator.calculatePercentSplit(totalAmount, percentages, scale);

            for (int i = 0; i < participantRequests.size(); i++) {
                ExpenseParticipantRequest pr = participantRequests.get(i);
                User user = userRepository.findById(pr.getUserId())
                        .orElseThrow(() -> new IllegalArgumentException("Nguoi dung khong hop le: " + pr.getUserId()));

                participants.add(ExpenseParticipant.builder()
                        .expense(expense)
                        .user(user)
                        .splitType(SplitType.PERCENT)
                        .percentage(pr.getPercentage())
                        .amount(calculatedAmounts.get(i))
                        .build());
            }
        } else if (splitType == SplitType.WEIGHT) {
            List<BigDecimal> weights = participantRequests.stream()
                    .map(ExpenseParticipantRequest::getWeight)
                    .collect(Collectors.toList());
            List<BigDecimal> calculatedAmounts = MoneySplitCalculator.calculateWeightSplit(totalAmount, weights, scale);

            for (int i = 0; i < participantRequests.size(); i++) {
                ExpenseParticipantRequest pr = participantRequests.get(i);
                User user = userRepository.findById(pr.getUserId())
                        .orElseThrow(() -> new IllegalArgumentException("Nguoi dung khong hop le: " + pr.getUserId()));

                participants.add(ExpenseParticipant.builder()
                        .expense(expense)
                        .user(user)
                        .splitType(SplitType.WEIGHT)
                        .weight(pr.getWeight())
                        .amount(calculatedAmounts.get(i))
                        .build());
            }
        } else if (splitType == SplitType.ITEM) {
            return new ArrayList<>();
        }

        return expenseParticipantRepository.saveAll(participants);
    }

    private List<ExpenseItem> processItems(Expense expense, CreateExpenseRequest request) {
        if (request.getSplitType() != SplitType.ITEM) {
            return new ArrayList<>();
        }

        List<ExpenseItemRequest> itemRequests = request.getItems();
        if (itemRequests == null || itemRequests.isEmpty()) {
            throw new IllegalArgumentException("Danh sach mon an khong duoc de rong khi chia theo ITEM");
        }

        List<ExpenseItem> items = new ArrayList<>();
        Map<Long, BigDecimal> userTotalShareMap = new HashMap<>();
        int scale = settingService.getDecimalScaleByGroupId(expense.getGroup().getId());

        for (ExpenseItemRequest ir : itemRequests) {
            BigDecimal totalPrice = ir.getQuantity().multiply(ir.getUnitPrice()).setScale(scale, RoundingMode.HALF_UP);

            ExpenseItem item = ExpenseItem.builder()
                    .expense(expense)
                    .itemName(ir.getItemName())
                    .quantity(ir.getQuantity())
                    .unitPrice(ir.getUnitPrice())
                    .totalPrice(totalPrice)
                    .build();

            item = expenseItemRepository.save(item);

            List<ItemParticipant> itemParticipants = new ArrayList<>();
            List<ItemParticipantRequest> ipRequests = ir.getParticipants();
            if (ipRequests != null && !ipRequests.isEmpty()) {
                int count = ipRequests.size();
                List<BigDecimal> equalShares = MoneySplitCalculator.calculateEqualSplit(totalPrice, count, scale);

                for (int i = 0; i < count; i++) {
                    ItemParticipantRequest ipr = ipRequests.get(i);
                    User user = userRepository.findById(ipr.getUserId())
                            .orElseThrow(() -> new IllegalArgumentException("Nguoi dung khong hop le: " + ipr.getUserId()));

                    BigDecimal share = ipr.getShareAmount() != null ? ipr.getShareAmount() : equalShares.get(i);

                    itemParticipants.add(ItemParticipant.builder()
                            .item(item)
                            .user(user)
                            .shareAmount(share)
                            .build());

                    userTotalShareMap.put(user.getId(), userTotalShareMap.getOrDefault(user.getId(), BigDecimal.ZERO).add(share));
                }
                itemParticipantRepository.saveAll(itemParticipants);
            }
            items.add(item);
        }

        // Save ExpenseParticipants for ITEM split
        List<ExpenseParticipant> expenseParticipants = new ArrayList<>();
        for (Long uId : userTotalShareMap.keySet()) {
            User user = userRepository.findById(uId).orElseThrow();
            expenseParticipants.add(ExpenseParticipant.builder()
                    .expense(expense)
                    .user(user)
                    .splitType(SplitType.ITEM)
                    .amount(userTotalShareMap.get(uId))
                    .build());
        }
        expenseParticipantRepository.saveAll(expenseParticipants);

        return items;
    }

    @Override
    @Transactional(readOnly = true)
    public ExpenseResponse getExpenseById(Long id) {
        Expense expense = expenseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay khoản chi tieu voi ID: " + id));

        List<ExpenseParticipant> participants = expenseParticipantRepository.findByExpenseId(id);
        List<ExpenseItem> items = expenseItemRepository.findByExpenseId(id);

        return mapToExpenseResponse(expense, participants, items);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ExpenseResponse> getExpensesByGroupId(Long groupId) {
        List<Expense> expenses = expenseRepository.findByGroupIdOrderByExpenseDateDesc(groupId);
        List<ExpenseResponse> responses = new ArrayList<>();

        for (Expense expense : expenses) {
            List<ExpenseParticipant> participants = expenseParticipantRepository.findByExpenseId(expense.getId());
            List<ExpenseItem> items = expenseItemRepository.findByExpenseId(expense.getId());
            responses.add(mapToExpenseResponse(expense, participants, items));
        }

        return responses;
    }

    @Override
    @Transactional
    public ExpenseResponse updateExpense(Long id, CreateExpenseRequest request) {
        Expense expense = expenseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay khoản chi tieu voi ID: " + id));

        // TASK BE2-EXP-02: Lock logic for settled expenses
        checkIfExpenseIsLocked(expense);

        expense.setTitle(request.getTitle());
        expense.setDescription(request.getDescription());
        expense.setTotalAmount(request.getTotalAmount());
        expense.setExpenseDate(request.getExpenseDate());
        expense.setReceiptUrl(request.getReceiptUrl());

        if (request.getCategoryId() != null) {
            Category cat = categoryRepository.findById(request.getCategoryId()).orElse(null);
            expense.setCategory(cat);
        }

        expense = expenseRepository.save(expense);

        // Delete old details and recreate
        expenseParticipantRepository.deleteByExpenseId(id);
        List<ExpenseItem> oldItems = expenseItemRepository.findByExpenseId(id);
        for (ExpenseItem item : oldItems) {
            itemParticipantRepository.deleteByItemId(item.getId());
        }
        expenseItemRepository.deleteByExpenseId(id);

        List<ExpenseParticipant> savedParticipants = processParticipants(expense, request);
        List<ExpenseItem> savedItems = processItems(expense, request);

        settlementEngineService.recalculateGroupDebts(expense.getGroup().getId());

        return mapToExpenseResponse(expense, savedParticipants, savedItems);
    }

    @Override
    @Transactional
    public void deleteExpense(Long id) {
        Expense expense = expenseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay khoản chi tieu voi ID: " + id));

        // TASK BE2-EXP-02: Lock logic for settled expenses
        checkIfExpenseIsLocked(expense);

        Long groupId = expense.getGroup().getId();
        expenseRepository.delete(expense);
        settlementEngineService.recalculateGroupDebts(groupId);
    }

    private void checkIfExpenseIsLocked(Expense expense) {
        List<Settlement> confirmedSettlements = settlementRepository.findByGroupIdAndStatus(
                expense.getGroup().getId(), SettlementStatus.CONFIRMED);

        if (!confirmedSettlements.isEmpty()) {
            throw new IllegalArgumentException("Nhom nay da co giao dich quyet toan da chot (CONFIRMED). Khoan chi tieu khong thể sửa/xóa!");
        }
    }

    private ExpenseResponse mapToExpenseResponse(Expense expense, List<ExpenseParticipant> participants, List<ExpenseItem> items) {
        List<ExpenseParticipantResponse> participantResponses = participants.stream()
                .map(p -> ExpenseParticipantResponse.builder()
                        .id(p.getId())
                        .userId(p.getUser().getId())
                        .userName(p.getUser().getFullName())
                        .userAvatar(p.getUser().getAvatarUrl())
                        .splitType(p.getSplitType())
                        .amount(p.getAmount())
                        .percentage(p.getPercentage())
                        .weight(p.getWeight())
                        .build())
                .collect(Collectors.toList());

        List<ExpenseItemResponse> itemResponses = items.stream()
                .map(item -> {
                    List<ItemParticipant> itemParts = itemParticipantRepository.findByItemId(item.getId());
                    List<ItemParticipantResponse> ipResponses = itemParts.stream()
                            .map(ip -> ItemParticipantResponse.builder()
                                    .id(ip.getId())
                                    .userId(ip.getUser().getId())
                                    .userName(ip.getUser().getFullName())
                                    .userAvatar(ip.getUser().getAvatarUrl())
                                    .shareAmount(ip.getShareAmount())
                                    .build())
                            .collect(Collectors.toList());

                    return ExpenseItemResponse.builder()
                            .id(item.getId())
                            .itemName(item.getItemName())
                            .quantity(item.getQuantity())
                            .unitPrice(item.getUnitPrice())
                            .totalPrice(item.getTotalPrice())
                            .participants(ipResponses)
                            .build();
                })
                .collect(Collectors.toList());

        return ExpenseResponse.builder()
                .id(expense.getId())
                .groupId(expense.getGroup().getId())
                .groupName(expense.getGroup().getName())
                .categoryId(expense.getCategory() != null ? expense.getCategory().getId() : null)
                .categoryName(expense.getCategory() != null ? expense.getCategory().getName() : null)
                .categoryIcon(expense.getCategory() != null ? expense.getCategory().getIcon() : null)
                .payerId(expense.getPayer().getId())
                .payerName(expense.getPayer().getFullName())
                .payerAvatar(expense.getPayer().getAvatarUrl())
                .title(expense.getTitle())
                .description(expense.getDescription())
                .totalAmount(expense.getTotalAmount())
                .expenseDate(expense.getExpenseDate())
                .receiptUrl(expense.getReceiptUrl())
                .createdAt(expense.getCreatedAt())
                .updatedAt(expense.getUpdatedAt())
                .participants(participantResponses)
                .items(itemResponses)
                .build();
    }
}
