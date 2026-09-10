class DebtEdge {
  final int debtorId;
  final String debtorName;

  final int creditorId;
  final String creditorName;

  final double amount;

  const DebtEdge({
    required this.debtorId,
    required this.debtorName,
    required this.creditorId,
    required this.creditorName,
    required this.amount,
  });

  factory DebtEdge.fromJson(
      Map<String, dynamic> json,
      ) {
    return DebtEdge(
      debtorId:
      (json['debtorId'] as num)
          .toInt(),

      debtorName:
      json['debtorName']
      as String? ??
          '',

      creditorId:
      (json['creditorId'] as num)
          .toInt(),

      creditorName:
      json['creditorName']
      as String? ??
          '',

      amount:
      (json['amount'] as num)
          .toDouble(),
    );
  }
}

class NetBalance {
  final int userId;

  final String fullName;

  final double netBalance;

  const NetBalance({
    required this.userId,
    required this.fullName,
    required this.netBalance,
  });

  factory NetBalance.fromJson(
      Map<String, dynamic> json,
      ) {
    return NetBalance(
      userId:
      (json['userId'] as num)
          .toInt(),

      fullName:
      json['fullName']
      as String? ??
          '',

      netBalance:
      (json['netBalance']
      as num)
          .toDouble(),
    );
  }
}

class DebtSummary {
  final double totalToPay;

  final double totalToReceive;

  final List<DebtEdge> youOwe;

  final List<DebtEdge> owedToYou;

  final List<NetBalance>
  netBalances;

  const DebtSummary({
    required this.totalToPay,
    required this.totalToReceive,
    required this.youOwe,
    required this.owedToYou,
    required this.netBalances,
  });

  factory DebtSummary.fromJson(
      Map<String, dynamic> json,
      ) {
    return DebtSummary(
      totalToPay:
      (json['totalToPay']
      as num? ??
          0)
          .toDouble(),

      totalToReceive:
      (json['totalToReceive']
      as num? ??
          0)
          .toDouble(),

      youOwe:
      ((json['youOwe']
      as List?) ??
          const [])
          .map(
            (e) =>
            DebtEdge.fromJson(
              e as Map<String, dynamic>,
            ),
      )
          .toList(),

      owedToYou:
      ((json['owedToYou']
      as List?) ??
          const [])
          .map(
            (e) =>
            DebtEdge.fromJson(
              e as Map<String, dynamic>,
            ),
      )
          .toList(),

      netBalances:
      ((json['netBalances']
      as List?) ??
          const [])
          .map(
            (e) =>
            NetBalance.fromJson(
              e as Map<String, dynamic>,
            ),
      )
          .toList(),
    );
  }
}

class SmartSettlementResult {
  final int beforeTransactionCount;

  final int afterTransactionCount;

  final List<DebtEdge> suggestions;

  const SmartSettlementResult({
    required this.beforeTransactionCount,
    required this.afterTransactionCount,
    required this.suggestions,
  });

  factory SmartSettlementResult.fromJson(
      Map<String, dynamic> json,
      ) {
    return SmartSettlementResult(
      beforeTransactionCount:
      (json['beforeTransactionCount']
      as num? ??
          0)
          .toInt(),

      afterTransactionCount:
      (json['afterTransactionCount']
      as num? ??
          0)
          .toInt(),

      suggestions:
      ((json['suggestions']
      as List?) ??
          const [])
          .map(
            (e) =>
            DebtEdge.fromJson(
              e as Map<String, dynamic>,
            ),
      )
          .toList(),
    );
  }
}

class ChartSlice {
  final String label;

  final double amount;

  const ChartSlice({
    required this.label,
    required this.amount,
  });

  factory ChartSlice.fromJson(
      Map<String, dynamic> json,
      ) {
    return ChartSlice(
      label:
      json['label']
      as String? ??
          'Khác',

      amount:
      (json['amount']
      as num? ??
          0)
          .toDouble(),
    );
  }
}

class FinancialStats {
  final String period;

  final double totalExpense;

  final double
  totalPaidByCurrentUser;

  final double totalDebtToPay;

  final double
  totalDebtToReceive;

  final List<ChartSlice>
  byCategory;

  final List<ChartSlice>
  byMember;

  const FinancialStats({
    required this.period,
    required this.totalExpense,
    required this.totalPaidByCurrentUser,
    required this.totalDebtToPay,
    required this.totalDebtToReceive,
    required this.byCategory,
    required this.byMember,
  });

  factory FinancialStats.fromJson(
      Map<String, dynamic> json,
      ) {
    return FinancialStats(
      period:
      json['period']
      as String? ??
          'MONTH',

      totalExpense:
      (json['totalExpense']
      as num? ??
          0)
          .toDouble(),

      totalPaidByCurrentUser:
      (json['totalPaidByCurrentUser']
      as num? ??
          0)
          .toDouble(),

      totalDebtToPay:
      (json['totalDebtToPay']
      as num? ??
          0)
          .toDouble(),

      totalDebtToReceive:
      (json['totalDebtToReceive']
      as num? ??
          0)
          .toDouble(),

      byCategory:
      ((json['byCategory']
      as List?) ??
          const [])
          .map(
            (e) =>
            ChartSlice.fromJson(
              e as Map<String, dynamic>,
            ),
      )
          .toList(),

      byMember:
      ((json['byMember']
      as List?) ??
          const [])
          .map(
            (e) =>
            ChartSlice.fromJson(
              e as Map<String, dynamic>,
            ),
      )
          .toList(),
    );
  }
}

class SettlementRecord {
  final int id;

  final int groupId;

  final int debtorId;

  final String debtorName;

  final int creditorId;

  final String creditorName;

  final double amount;

  final String status;

  final String? paymentMethod;

  const SettlementRecord({
    required this.id,
    required this.groupId,
    required this.debtorId,
    required this.debtorName,
    required this.creditorId,
    required this.creditorName,
    required this.amount,
    required this.status,
    this.paymentMethod,
  });

  factory SettlementRecord.fromJson(
      Map<String, dynamic> json,
      ) {
    return SettlementRecord(
      id:
      (json['id'] as num)
          .toInt(),

      groupId:
      (json['groupId'] as num)
          .toInt(),

      debtorId:
      (json['debtorId'] as num)
          .toInt(),

      debtorName:
      json['debtorName']
      as String? ??
          '',

      creditorId:
      (json['creditorId'] as num)
          .toInt(),

      creditorName:
      json['creditorName']
      as String? ??
          '',

      amount:
      (json['amount'] as num)
          .toDouble(),

      status:
      json['status']
      as String? ??
          'PENDING',

      paymentMethod:
      json['paymentMethod']
      as String?,
    );
  }
}