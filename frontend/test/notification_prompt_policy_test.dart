import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/notifications/notification_prompt_policy.dart';

void main() {
  final now = DateTime(2026, 11, 26, 12, 0);

  test('prompts on first time', () {
    expect(
      shouldPromptNotifications(count: 0, last: null, now: now),
      isTrue,
    );
  });

  test('waits 7 days after "Để sau"', () {
    final sixDaysAgo = now.subtract(const Duration(days: 6));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    expect(
      shouldPromptNotifications(count: 1, last: sixDaysAgo, now: now),
      isFalse,
    );
    expect(
      shouldPromptNotifications(count: 1, last: sevenDaysAgo, now: now),
      isTrue,
    );
  });

  test('never more than twice', () {
    final longAgo = now.subtract(const Duration(days: 30));
    expect(
      shouldPromptNotifications(count: 2, last: longAgo, now: now),
      isFalse,
    );
  });
}

