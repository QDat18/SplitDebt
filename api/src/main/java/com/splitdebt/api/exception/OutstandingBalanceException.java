/**
 * Trách nhiệm file: Ngoại lệ khi người dùng còn công nợ khác 0 trong nhóm nên chưa thể xoá tài khoản (409).
 */

package com.splitdebt.api.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.List;

@Getter
public class OutstandingBalanceException extends RuntimeException {

    private final List<GroupBalance> groups;

    public OutstandingBalanceException(String message, List<GroupBalance> groups) {
        super(message);
        this.groups = groups;
    }

    @Getter
    @AllArgsConstructor
    public static class GroupBalance {
        private final Long id;
        private final String name;
        private final BigDecimal balance;
    }
}

