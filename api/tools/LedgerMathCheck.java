package com.splitdebt.api.ledger;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.TreeMap;

/** Lightweight invariant checks that can run with javac only (no Maven required). */
public final class LedgerMathCheck {
    private LedgerMathCheck() {}

    private static void check(boolean value, String message) {
        if (!value) throw new AssertionError(message);
    }

    public static void main(String[] args) {
        check(LedgerMath.split(100, List.of(3L, 2L, 1L)).equals(Map.of(1L, 34L, 2L, 33L, 3L, 33L)),
                "equal split rounding failed");
        check(LedgerMath.split(1, List.of(2L, 1L)).equals(Map.of(1L, 1L, 2L, 0L)),
                "single minor-unit split failed");

        for (List<Long> invalid : List.of(List.<Long>of(), List.of(1L, 1L))) {
            try {
                LedgerMath.split(100, invalid);
                throw new AssertionError("invalid participant list was accepted");
            } catch (IllegalArgumentException expected) {
                // expected
            }
        }

        Map<Long, BigDecimal> ratios = new LinkedHashMap<>();
        ratios.put(1L, new BigDecimal("33"));
        ratios.put(2L, new BigDecimal("67"));
        Map<Long, Long> ratioSplit = LedgerMath.splitByRatios(100, ratios);
        check(ratioSplit.values().stream().mapToLong(Long::longValue).sum() == 100,
                "ratio split did not conserve money");

        Random random = new Random(42);
        for (int trial = 0; trial < 10_000; trial++) {
            int n = 2 + random.nextInt(99);
            List<Long> people = new ArrayList<>();
            for (long i = 1; i <= n; i++) people.add(i);
            long amount = 1 + Math.floorMod(random.nextLong(), 1_000_000_000_000L);

            Map<Long, Long> shares = LedgerMath.split(amount, people);
            check(shares.values().stream().mapToLong(Long::longValue).sum() == amount,
                    "equal split lost money");
            check(shares.values().stream().mapToLong(Long::longValue).max().orElseThrow()
                            - shares.values().stream().mapToLong(Long::longValue).min().orElseThrow() <= 1,
                    "equal split differs by more than one minor unit");

            Map<Long, Long> balances = new TreeMap<>();
            shares.forEach((person, share) -> balances.put(person, -share));
            balances.merge(people.get(random.nextInt(n)), amount, Long::sum);

            List<LedgerMath.Transfer> transfers = LedgerMath.simplify(balances);
            check(transfers.size() <= n - 1, "settlement produced too many transfers");
            Map<Long, Long> residual = new TreeMap<>(balances);
            for (LedgerMath.Transfer transfer : transfers) {
                check(transfer.amount() > 0, "non-positive transfer");
                check(transfer.fromId() != transfer.toId(), "self transfer");
                residual.merge(transfer.fromId(), transfer.amount(), Long::sum);
                residual.merge(transfer.toId(), -transfer.amount(), Long::sum);
            }
            check(residual.values().stream().allMatch(value -> value == 0L),
                    "settlement did not clear all balances");
        }

        System.out.println("PASS: LedgerMath invariants, rounding, ratios and 10,000 randomized settlements.");
    }
}
