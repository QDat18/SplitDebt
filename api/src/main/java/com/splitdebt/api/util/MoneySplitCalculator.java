package com.splitdebt.api.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

public class MoneySplitCalculator {

    public static final int DEFAULT_SCALE = 2; // Mặc định 2 chữ số thập phân (USD, EUR,...)
    private static final RoundingMode ROUNDING_MODE = RoundingMode.HALF_UP;

    // chia đều (mặc định scale = 2)
    public static List<BigDecimal> calculateEqualSplit(BigDecimal totalAmount, int count) {
        return calculateEqualSplit(totalAmount, count, DEFAULT_SCALE);
    }

    // chia đều hỗ trợ scale linh hoạt (ví dụ: scale = 0 cho VNĐ, scale = 2 cho USD)
    public static List<BigDecimal> calculateEqualSplit(BigDecimal totalAmount, int count, int scale) {
        if (count <= 0) {
            throw new IllegalArgumentException("Số lượng người tham gia phải lớn hơn 0");
        }

        BigDecimal baseAmount = totalAmount.divide(BigDecimal.valueOf(count), scale, RoundingMode.DOWN);
        BigDecimal sumBase = baseAmount.multiply(BigDecimal.valueOf(count));
        BigDecimal remainder = totalAmount.subtract(sumBase);

        List<BigDecimal> results = new ArrayList<>(count);
        BigDecimal step = BigDecimal.ONE.movePointLeft(scale); // scale = 2 -> 0.01, scale = 0 -> 1

        for (int i = 0; i < count; i++) {
            if (remainder.compareTo(BigDecimal.ZERO) > 0) {
                results.add(baseAmount.add(step));
                remainder = remainder.subtract(step);
            } else {
                results.add(baseAmount);
            }
        }
        return results;
    }

    // chia theo phần trăm (mặc định scale = 2)
    public static List<BigDecimal> calculatePercentSplit(BigDecimal totalAmount, List<BigDecimal> percentages) {
        return calculatePercentSplit(totalAmount, percentages, DEFAULT_SCALE);
    }

    // chia theo phần trăm hỗ trợ scale linh hoạt
    public static List<BigDecimal> calculatePercentSplit(BigDecimal totalAmount, List<BigDecimal> percentages, int scale) {
        BigDecimal totalPercent = percentages.stream().reduce(BigDecimal.ZERO, BigDecimal::add);

        if (totalPercent.setScale(scale, ROUNDING_MODE).compareTo(BigDecimal.valueOf(100).setScale(scale, ROUNDING_MODE)) != 0) {
            throw new IllegalArgumentException("Tổng phần trăm phân chia (" + totalPercent + "%) không bằng 100%");
        }

        List<BigDecimal> results = new ArrayList<>();
        BigDecimal sumCalculated = BigDecimal.ZERO;
        int maxPercentIndex = 0;
        BigDecimal maxPercent = BigDecimal.ZERO;

        for (int i = 0; i < percentages.size(); i++) {
            BigDecimal p = percentages.get(i);
            BigDecimal amount = totalAmount.multiply(p).divide(BigDecimal.valueOf(100), scale, ROUNDING_MODE);
            results.add(amount);
            sumCalculated = sumCalculated.add(amount);

            if (p.compareTo(maxPercent) > 0) {
                maxPercent = p;
                maxPercentIndex = i;
            }
        }

        // Xử lý sai số làm tròn (Rounding Compensation)
        BigDecimal diff = totalAmount.subtract(sumCalculated);
        if (diff.compareTo(BigDecimal.ZERO) != 0 && !results.isEmpty()) {
            results.set(maxPercentIndex, results.get(maxPercentIndex).add(diff));
        }

        return results;
    }

    // chia theo trọng số (mặc định scale = 2)
    public static List<BigDecimal> calculateWeightSplit(BigDecimal totalAmount, List<BigDecimal> weights) {
        return calculateWeightSplit(totalAmount, weights, DEFAULT_SCALE);
    }

    // chia theo trọng số hỗ trợ scale linh hoạt
    public static List<BigDecimal> calculateWeightSplit(BigDecimal totalAmount, List<BigDecimal> weights, int scale) {
        BigDecimal totalWeight = weights.stream().reduce(BigDecimal.ZERO, BigDecimal::add);

        if (totalWeight.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Tổng trọng số phải lớn hơn 0");
        }

        List<BigDecimal> results = new ArrayList<>();
        BigDecimal sumCalculated = BigDecimal.ZERO;
        int maxWeightIndex = 0;
        BigDecimal maxWeight = BigDecimal.ZERO;

        for (int i = 0; i < weights.size(); i++) {
            BigDecimal w = weights.get(i);
            BigDecimal amount = totalAmount.multiply(w).divide(totalWeight, scale, ROUNDING_MODE);
            results.add(amount);
            sumCalculated = sumCalculated.add(amount);

            if (w.compareTo(maxWeight) > 0) {
                maxWeight = w;
                maxWeightIndex = i;
            }
        }

        // Xử lý sai số làm tròn (Rounding Compensation)
        BigDecimal diff = totalAmount.subtract(sumCalculated);
        if (diff.compareTo(BigDecimal.ZERO) != 0 && !results.isEmpty()) {
            results.set(maxWeightIndex, results.get(maxWeightIndex).add(diff));
        }

        return results;
    }

    // chia theo số tiền cụ thể (mặc định scale = 2)
    public static void validateAmountSplit(BigDecimal totalAmount, List<BigDecimal> amounts) {
        validateAmountSplit(totalAmount, amounts, DEFAULT_SCALE);
    }

    // chia theo số tiền cụ thể hỗ trợ scale linh hoạt
    public static void validateAmountSplit(BigDecimal totalAmount, List<BigDecimal> amounts, int scale) {
        BigDecimal sum = amounts.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        if (sum.setScale(scale, ROUNDING_MODE).compareTo(totalAmount.setScale(scale, ROUNDING_MODE)) != 0) {
            throw new IllegalArgumentException("Tổng số tiền phân chia (" + sum + ") không khớp với tổng tiền chi tiêu (" + totalAmount + ")");
        }
    }
}
