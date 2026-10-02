package com.splitdebt.api.service;

import com.splitdebt.api.dto.settlement.NetBalanceDto;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class SmartSettlementServiceTest {

    private final SmartSettlementService service =
            new SmartSettlementService();

    @Test
    void shouldSimplifyCircularDebtAndPreserveTotal() {

        var balances =
                List.of(

                        new NetBalanceDto(
                                1L,
                                "An",
                                new BigDecimal("-100.00")
                        ),

                        new NetBalanceDto(
                                2L,
                                "Binh",
                                new BigDecimal("-50.00")
                        ),

                        new NetBalanceDto(
                                3L,
                                "Chi",
                                new BigDecimal("150.00")
                        )
                );

        var result =
                service.optimize(
                        10L,
                        4,
                        balances
                );

        assertThat(
                result.afterTransactionCount()
        ).isEqualTo(2);

        assertThat(
                result.suggestions()
        )
                .extracting(
                        x -> x.amount()
                )
                .containsExactlyInAnyOrder(
                        new BigDecimal("100.00"),
                        new BigDecimal("50.00")
                );

        assertThat(
                result.suggestions()
                        .stream()
                        .map(
                                x -> x.amount()
                        )
                        .reduce(
                                BigDecimal.ZERO,
                                BigDecimal::add
                        )
        ).isEqualByComparingTo(
                "150.00"
        );
    }

    @Test
    void balancedGroupProducesNoSuggestion() {

        var result =
                service.optimize(
                        1L,
                        0,
                        List.of(

                                new NetBalanceDto(
                                        1L,
                                        "A",
                                        BigDecimal.ZERO
                                ),

                                new NetBalanceDto(
                                        2L,
                                        "B",
                                        BigDecimal.ZERO
                                )
                        )
                );

        assertThat(
                result.suggestions()
        ).isEmpty();

        assertThat(
                result.afterTransactionCount()
        ).isZero();
    }
}