import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/widgets/grouped_list.dart';
import 'package:split_debt/features/profile/notification_settings_screen.dart';
import 'package:split_debt/features/profile/user_preferences.dart';

class FakeRepo implements UserPreferencesRepository {
  UserPreferences prefs;
  FakeRepo(this.prefs);

  @override
  Future<UserPreferences> fetch() async => prefs;

  @override
  Future<UserPreferences> save(UserPreferences p) async {
    prefs = p;
    return p;
  }
}

void main() {
  testWidgets('renders all three notification switch tiles and toggles group message',
      (tester) async {
    final fake = FakeRepo(
      const UserPreferences(
        notifyOnDebtReminder: true,
        notifyOnSettlement: true,
        notifyOnGroupMessage: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesRepositoryProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(
          home: NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhắc thanh toán nợ'), findsOneWidget);
    expect(find.text('Cập nhật quyết toán'), findsOneWidget);
    expect(find.text('Tin nhắn nhóm'), findsOneWidget);

    final switchTiles = find.byType(GroupedSwitchTile);
    expect(switchTiles, findsNWidgets(3));

    // Toggle group message switch (3rd switch)
    final groupSwitch = find.descendant(
      of: switchTiles.at(2),
      matching: find.byType(Switch),
    );
    expect(groupSwitch, findsOneWidget);
    await tester.tap(groupSwitch);
    await tester.pumpAndSettle();

    expect(fake.prefs.notifyOnGroupMessage, isFalse);
  });
}
