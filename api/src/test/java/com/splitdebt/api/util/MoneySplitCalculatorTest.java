/**
 * Trách nhiệm file: Kiểm thử hành vi của Money Split Calculator Test, bao gồm các trường hợp thành công và biên quan trọng.
 */

package com.splitdebt.api.util;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class MoneySplitCalculatorTest {

    @Test
    void equalSplitPreservesTotalForVndRemainder() {
        List<BigDecimal> result = MoneySplitCalculator.calculateEqualSplit(
                new BigDecimal("100000"), 3, 0);

        assertEquals(List.of(
                new BigDecimal("33334"),
                new BigDecimal("33333"),
                new BigDecimal("33333")), result);
        assertEquals(new BigDecimal("100000"),
                result.stream().reduce(BigDecimal.ZERO, BigDecimal::add));
    }

    @Test
    void percentSplitRejectsNegativeCompensationInput() {
        assertThrows(IllegalArgumentException.class, () ->
                MoneySplitCalculator.calculatePercentSplit(
                        new BigDecimal("100"),
                        List.of(new BigDecimal("110"), new BigDecimal("-10")),
                        2));
    }

    @Test
    void amountSplitRejectsNullOrNonPositiveShares() {
        assertThrows(IllegalArgumentException.class, () ->
                MoneySplitCalculator.validateAmountSplit(
                        new BigDecimal("100"),
                        List.of(new BigDecimal("100"), BigDecimal.ZERO),
                        2));
    }

    @Test
    void weightSplitRejectsNegativeWeightsEvenWhenTotalIsPositive() {
        assertThrows(IllegalArgumentException.class, () ->
                MoneySplitCalculator.calculateWeightSplit(
                        new BigDecimal("100"),
                        List.of(new BigDecimal("2"), new BigDecimal("-1")),
                        2));
    }
}
