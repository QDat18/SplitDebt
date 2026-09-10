import '../../../core/network/dio_client.dart';

import '../models/settlement_models.dart';

class SettlementApiService {
  final _dio = DioClient().dio;

  Map<String, dynamic> _data(
      dynamic responseData,
      ) {
    final map =
    responseData as Map<String, dynamic>;

    return map['data']
    as Map<String, dynamic>;
  }

  Future<DebtSummary> getDebtSummary(
      int groupId,
      int userId,
      ) async {
    final response = await _dio.get(
      '/groups/$groupId/debts',
      queryParameters: {
        'userId': userId,
      },
    );

    return DebtSummary.fromJson(
      _data(response.data),
    );
  }

  Future<SmartSettlementResult>
  getSmartSettlement(
      int groupId,
      int userId,
      ) async {
    final response = await _dio.get(
      '/groups/$groupId/smart-settlement',
      queryParameters: {
        'userId': userId,
      },
    );

    return SmartSettlementResult.fromJson(
      _data(response.data),
    );
  }

  Future<FinancialStats> getStats(
      int groupId,
      int userId,
      String period,
      ) async {
    final response = await _dio.get(
      '/groups/$groupId/stats',
      queryParameters: {
        'userId': userId,
        'period': period,
      },
    );

    return FinancialStats.fromJson(
      _data(response.data),
    );
  }

  Future<List<SettlementRecord>>
  getSettlements(
      int groupId,
      int userId,
      ) async {
    final response = await _dio.get(
      '/groups/$groupId/settlements',
      queryParameters: {
        'userId': userId,
      },
    );

    final data =
        (response.data
        as Map<String, dynamic>)['data']
        as List? ??
            const [];

    return data
        .map(
          (e) =>
          SettlementRecord.fromJson(
            e as Map<String, dynamic>,
          ),
    )
        .toList();
  }

  Future<SettlementRecord>
  createSettlement({
    required int groupId,
    required int currentUserId,
    required DebtEdge suggestion,
  }) async {
    final response = await _dio.post(
      '/groups/$groupId/settlements',
      queryParameters: {
        'userId': currentUserId,
      },
      data: {
        'debtorId':
        suggestion.debtorId,
        'creditorId':
        suggestion.creditorId,
        'amount':
        suggestion.amount,
      },
    );

    return SettlementRecord.fromJson(
      _data(response.data),
    );
  }

  Future<SettlementRecord> markPaid({
    required int groupId,
    required int settlementId,
    required int debtorUserId,
    required String paymentMethod,
  }) async {
    final response = await _dio.post(
      '/groups/$groupId/settlements/'
          '$settlementId/pay',
      data: {
        'debtorUserId':
        debtorUserId,
        'paymentMethod':
        paymentMethod,
      },
    );

    return SettlementRecord.fromJson(
      _data(response.data),
    );
  }

  Future<SettlementRecord> confirm({
    required int groupId,
    required int settlementId,
    required int creditorUserId,
  }) async {
    final response = await _dio.post(
      '/groups/$groupId/settlements/'
          '$settlementId/confirm',
      data: {
        'creditorUserId':
        creditorUserId,
      },
    );

    return SettlementRecord.fromJson(
      _data(response.data),
    );
  }
}