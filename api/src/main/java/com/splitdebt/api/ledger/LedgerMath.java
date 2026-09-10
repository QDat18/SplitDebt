package com.splitdebt.api.ledger;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public final class LedgerMath {
    private LedgerMath() {}

    public record Transfer(long fromId, long toId, long amount) {}

    public static Map<Long, Long> split(long amount, List<Long> people) {
        check(amount > 0 && amount <= 1_000_000_000_000L,
                "Amount must be positive and no more than 1,000,000,000,000 minor units.");
        check(people != null && !people.isEmpty(), "Choose at least one participant.");
        List<Long> sorted = people.stream().distinct().sorted().toList();
        check(sorted.size() == people.size(), "Choose unique participants.");
        Map<Long, Long> result = new LinkedHashMap<>();
        for (int i = 0; i < sorted.size(); i++) {
            result.put(sorted.get(i), amount / sorted.size() + (i < amount % sorted.size() ? 1 : 0));
        }
        return result;
    }

    /**
     * Splits an integer minor-unit total using positive decimal ratios while preserving every unit.
     * Floors each raw share first, then distributes the remaining units by largest fractional remainder
     * with member id as a deterministic tie-breaker.
     */
    public static Map<Long, Long> splitByRatios(long total, Map<Long, BigDecimal> ratios) {
        check(total > 0, "Amount must be positive.");
        check(ratios != null && !ratios.isEmpty(), "Choose at least one participant.");
        BigDecimal ratioTotal = ratios.values().stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        check(ratioTotal.compareTo(BigDecimal.ZERO) > 0, "Split values must be positive.");

        record Part(long id, long base, BigDecimal remainder) {}
        List<Part> parts = new ArrayList<>();
        long assigned = 0;
        for (var entry : new TreeMap<>(ratios).entrySet()) {
            check(entry.getValue() != null && entry.getValue().compareTo(BigDecimal.ZERO) > 0,
                    "Split values must be positive.");
            BigDecimal raw = BigDecimal.valueOf(total).multiply(entry.getValue()).divide(ratioTotal, 16, RoundingMode.HALF_UP);
            long base = raw.setScale(0, RoundingMode.FLOOR).longValueExact();
            assigned += base;
            parts.add(new Part(entry.getKey(), base, raw.subtract(BigDecimal.valueOf(base))));
        }
        long remaining = total - assigned;
        parts.sort(Comparator.comparing(Part::remainder).reversed().thenComparingLong(Part::id));
        Map<Long, Long> result = new TreeMap<>();
        for (Part part : parts) result.put(part.id(), part.base());
        for (int i = 0; i < remaining; i++) {
            Part part = parts.get(i % parts.size());
            result.put(part.id(), result.get(part.id()) + 1);
        }
        return result;
    }

    public static List<Transfer> simplify(Map<Long, Long> balances) {
        Map<Long, Long> remaining = new TreeMap<>(balances);
        List<Transfer> result = new ArrayList<>();
        while (true) {
            Long debtor = remaining.entrySet().stream()
                    .filter(e -> e.getValue() < 0)
                    .min(Comparator.<Map.Entry<Long, Long>>comparingLong(Map.Entry::getValue)
                            .thenComparingLong(Map.Entry::getKey))
                    .map(Map.Entry::getKey).orElse(null);
            Long creditor = remaining.entrySet().stream()
                    .filter(e -> e.getValue() > 0)
                    .max(Comparator.<Map.Entry<Long, Long>>comparingLong(Map.Entry::getValue)
                            .thenComparing((a, b) -> Long.compare(b.getKey(), a.getKey())))
                    .map(Map.Entry::getKey).orElse(null);
            if (debtor == null || creditor == null) break;
            long amount = Math.min(-remaining.get(debtor), remaining.get(creditor));
            result.add(new Transfer(debtor, creditor, amount));
            remaining.put(debtor, remaining.get(debtor) + amount);
            remaining.put(creditor, remaining.get(creditor) - amount);
        }
        check(remaining.values().stream().allMatch(v -> v == 0), "Ledger is not balanced.");
        return result;
    }

    private static void check(boolean value, String message) {
        if (!value) throw new IllegalArgumentException(message);
    }
}
