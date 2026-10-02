// Trách nhiệm file: Thực hiện các HTTP request của settlement API service và ánh xạ phản hồi backend.

import '../../../core/network/dio_client.dart';

import '../models/settlement_models.dart';

class SettlementApiService {
  final _dio = DioClient().dio;

  Map<String, dynamic> _data(
    dynamic responseData,
  ) {
    final map = responseData as Map<String, dynamic>;

    return map['data'] as Map<String, dynamic>;
  }

  Future<DebtSummary> getDebtSummary(
    int groupId,
  ) async {
    final response = await _dio.get(
      '/groups/$groupId/debts',
    );

    return DebtSummary.fromJson(
      _data(response.data),
    );
  }

  Future<SmartSettlementResult> getSmartSettlement(
    int groupId,
  ) async {
    final response = await _dio.get(
      '/groups/$groupId/smart-settlement',
    );

    return SmartSettlementResult.fromJson(
      _data(response.data),
    );
  }

  Future<FinancialStats> getStats(
    int groupId,
    String period,
  ) async {
    final response = await _dio.get(
      '/groups/$groupId/stats',
      queryParameters: {
        'period': period,
      },
    );

    return FinancialStats.fromJson(
      _data(response.data),
    );
  }

  Future<List<SettlementRecord>> getSettlements(
    int groupId,
  ) async {
    final response = await _dio.get(
      '/groups/$groupId/settlements',
    );

    final data =
        (response.data as Map<String, dynamic>)['data'] as List? ?? const [];

    return data
        .map(
          (e) => SettlementRecord.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<SettlementRecord> createSettlement({
    required int groupId,
    required DebtEdge suggestion,
  }) async {
    final response = await _dio.post(
      '/groups/$groupId/settlements',
      data: {
        'debtorId': suggestion.debtorId,
        'creditorId': suggestion.creditorId,
        'amount': suggestion.amount,
      },
    );

    return SettlementRecord.fromJson(
      _data(response.data),
    );
  }

  Future<SettlementRecord> markPaid({
    required int groupId,
    required int settlementId,
    required String paymentMethod,
  }) async {
    final response = await _dio.post(
      '/groups/$groupId/settlements/'
      '$settlementId/pay',
      data: {
        'paymentMethod': paymentMethod,
      },
    );

    return SettlementRecord.fromJson(
      _data(response.data),
    );
  }

  Future<SettlementRecord> confirm({
    required int groupId,
    required int settlementId,
  }) async {
    final response = await _dio.post(
      '/groups/$groupId/settlements/'
      '$settlementId/confirm',
      data: const <String, dynamic>{},
    );

    return SettlementRecord.fromJson(
      _data(response.data),
    );
  }
}
