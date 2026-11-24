import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/notifications/notification_merge.dart';

void main() {
  group('applyPendingReads', () {
    test('pending read ids override stale isRead=false', () {
      final fetched = [
        {'id': 1, 'isRead': false},
        {'id': 2, 'isRead': false},
      ];
      final pending = {1};

      final result = applyPendingReads(fetched, pending);

      expect(result[0]['id'], 1);
      expect(result[0]['isRead'], true);
      expect(result[1]['id'], 2);
      expect(result[1]['isRead'], false);
    });

    test('does not mutate input list', () {
      final fetched = [
        {'id': 1, 'isRead': false},
      ];
      final pending = {1};

      applyPendingReads(fetched, pending);

      expect(fetched[0]['isRead'], false);
    });

    test('empty pending returns equal content', () {
      final fetched = [
        {'id': 1, 'isRead': false},
        {'id': 2, 'isRead': true},
      ];
      final pending = <Object>{};

      final result = applyPendingReads(fetched, pending);

      expect(result[0]['isRead'], false);
      expect(result[1]['isRead'], true);
    });
  });
}

