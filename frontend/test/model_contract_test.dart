// Trách nhiệm file: Kiểm thử việc giải mã response envelope và các model dùng trong hợp đồng Flutter–backend.

import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/network/api_response.dart';
import 'package:split_debt/features/groups/models/group_model.dart';
import 'package:split_debt/features/settlements/models/settlement_models.dart';

void main() {
  group('API contract models', () {
    test('unwraps the standard backend response envelope', () {
      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        {
          'status': 200,
          'message': 'OK',
          'data': {'id': 7},
        },
        (json) => Map<String, dynamic>.from(json! as Map),
      );

      expect(response.status, 200);
      expect(response.message, 'OK');
      expect(response.data, {'id': 7});
    });

    test('accepts numeric backend group ids and balances', () {
      final group = GroupModel.fromJson({
        'id': 42,
        'name': 'Chuyến đi',
        'currentUserRole': 'OWNER',
        'memberCount': 3,
        'userBalance': 125000.5,
      });

      expect(group.id, '42');
      expect(group.isOwner, isTrue);
      expect(group.memberCount, 3);
      expect(group.userBalance, 125000.5);
    });

    test('parses debt summary values without losing numeric precision type',
        () {
      final summary = DebtSummary.fromJson({
        'totalToPay': 100000,
        'totalToReceive': 0,
        'youOwe': [
          {
            'debtorId': 1,
            'debtorName': 'An',
            'creditorId': 2,
            'creditorName': 'Bình',
            'amount': 100000,
          },
        ],
        'owedToYou': <dynamic>[],
        'netBalances': <dynamic>[],
      });

      expect(summary.totalToPay, 100000.0);
      expect(summary.youOwe.single.creditorName, 'Bình');
      expect(summary.youOwe.single.amount, 100000.0);
    });
  });
}
