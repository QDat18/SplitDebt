import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/chat/chat_poll_policy.dart';

void main() {
  group('nextChatPollDelay', () {
    final now = DateTime(2026, 11, 27, 12, 0, 0);

    test('returns 5s when lastActivity is null', () {
      expect(
        nextChatPollDelay(now: now, lastActivity: null, lastPollFailed: false),
        equals(kChatSlowPoll),
      );
    });

    test('returns 1s when activity was 10s or 29s ago, 5s at 30s', () {
      expect(
        nextChatPollDelay(
          now: now,
          lastActivity: now.subtract(const Duration(seconds: 10)),
          lastPollFailed: false,
        ),
        equals(kChatFastPoll),
      );
      expect(
        nextChatPollDelay(
          now: now,
          lastActivity: now.subtract(const Duration(seconds: 29)),
          lastPollFailed: false,
        ),
        equals(kChatFastPoll),
      );
      expect(
        nextChatPollDelay(
          now: now,
          lastActivity: now.subtract(const Duration(seconds: 30)),
          lastPollFailed: false,
        ),
        equals(kChatSlowPoll),
      );
    });

    test('returns 5s when lastPollFailed even with recent activity', () {
      expect(
        nextChatPollDelay(
          now: now,
          lastActivity: now.subtract(const Duration(seconds: 1)),
          lastPollFailed: true,
        ),
        equals(kChatSlowPoll),
      );
    });
  });
}

