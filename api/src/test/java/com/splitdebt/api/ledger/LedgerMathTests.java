package com.splitdebt.api.ledger;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.TreeMap;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class LedgerMathTests {
    @Test
    void equalSplitIsDeterministicAndConservesEveryMinorUnit() {
        assertEquals(Map.of(1L, 34L, 2L, 33L, 3L, 33L),
                LedgerMath.split(100, List.of(3L, 2L, 1L)));
        assertEquals(Map.of(1L, 1L, 2L, 0L),
                LedgerMath.split(1, List.of(2L, 1L)));
    }

    @Test
    void equalSplitRejectsInvalidAmountsAndDuplicateParticipants() {
        assertThrows(IllegalArgumentException.class, () -> LedgerMath.split(0, List.of(1L)));
        assertThrows(IllegalArgumentException.class, () -> LedgerMath.split(-1, List.of(1L)));
        assertThrows(IllegalArgumentException.class, () -> LedgerMath.split(1_000_000_000_001L, List.of(1L)));
        assertThrows(IllegalArgumentException.class, () -> LedgerMath.split(100, List.of()));
        assertThrows(IllegalArgumentException.class, () -> LedgerMath.split(100, List.of(1L, 1L)));
    }

    @Test
    void ratioSplitUsesLargestRemainderAndConservesMoney() {
        Map<Long, BigDecimal> ratios = new LinkedHashMap<>();
        ratios.put(1L, new BigDecimal("1"));
        ratios.put(2L, new BigDecimal("1"));
        ratios.put(3L, new BigDecimal("1"));
        assertEquals(Map.of(1L, 34L, 2L, 33L, 3L, 33L), LedgerMath.splitByRatios(100, ratios));

        ratios = Map.of(1L, new BigDecimal("33"), 2L, new BigDecimal("67"));
        Map<Long, Long> result = LedgerMath.splitByRatios(101, ratios);
        assertEquals(101L, result.values().stream().mapToLong(Long::longValue).sum());
        assertEquals(33L, result.get(1L));
        assertEquals(68L, result.get(2L));
    }

    @Test
    void ratioSplitRejectsNonPositiveRatios() {
        assertThrows(IllegalArgumentException.class,
                () -> LedgerMath.splitByRatios(100, Map.of(1L, BigDecimal.ZERO, 2L, BigDecimal.ONE)));
        assertThrows(IllegalArgumentException.class,
                () -> LedgerMath.splitByRatios(100, Map.of()));
    }

    @Test
    void smartSettlementClearsBalancesWithoutSelfTransfers() {
        Map<Long, Long> balances = Map.of(1L, 700L, 2L, -200L, 3L, -500L);
        List<LedgerMath.Transfer> transfers = LedgerMath.simplify(balances);
        assertEquals(2, transfers.size());
        Map<Long, Long> residual = new TreeMap<>(balances);
        for (var transfer : transfers) {
            assertTrue(transfer.amount() > 0);
            assertNotEquals(transfer.fromId(), transfer.toId());
            residual.merge(transfer.fromId(), transfer.amount(), Long::sum);
            residual.merge(transfer.toId(), -transfer.amount(), Long::sum);
        }
        assertTrue(residual.values().stream().allMatch(v -> v == 0));
    }

    @Test
    void smartSettlementRejectsUnbalancedLedger() {
        assertThrows(IllegalArgumentException.class, () -> LedgerMath.simplify(Map.of(1L, 10L, 2L, -9L)));
    }

    @Test
    void randomizedInvariantsHoldAcrossTenThousandLedgers() {
        Random random = new Random(42);
        for (int trial = 0; trial < 10_000; trial++) {
            int n = 2 + random.nextInt(30);
            List<Long> people = java.util.stream.LongStream.rangeClosed(1, n).boxed().toList();
            long amount = 1 + Math.floorMod(random.nextLong(), 1_000_000_000L);
            Map<Long, Long> shares = LedgerMath.split(amount, people);
            assertEquals(amount, shares.values().stream().mapToLong(Long::longValue).sum());

            Map<Long, Long> balances = new TreeMap<>();
            shares.forEach((id, share) -> balances.put(id, -share));
            balances.merge(people.get(random.nextInt(n)), amount, Long::sum);
            List<LedgerMath.Transfer> transfers = LedgerMath.simplify(balances);
            assertTrue(transfers.size() <= n - 1);

            Map<Long, Long> residual = new TreeMap<>(balances);
            for (var transfer : transfers) {
                residual.merge(transfer.fromId(), transfer.amount(), Long::sum);
                residual.merge(transfer.toId(), -transfer.amount(), Long::sum);
            }
            assertTrue(residual.values().stream().allMatch(v -> v == 0));
        }
    }
}
