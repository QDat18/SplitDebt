import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/profile/user_preferences.dart';

class FakeUserPreferencesRepository implements UserPreferencesRepository {
  UserPreferences current;
  UserPreferences? lastSaved;
  bool shouldThrow = false;
  int saveCount = 0;
  Completer<void>? saveCompleter;

  FakeUserPreferencesRepository({
    this.current = const UserPreferences(
      notifyOnDebtReminder: true,
      notifyOnSettlement: false,
    ),
  });

  @override
  Future<UserPreferences> fetch() async {
    if (shouldThrow) throw Exception('Fetch failed');
    return current;
  }

  @override
  Future<UserPreferences> save(UserPreferences p) async {
    saveCount++;
    if (saveCompleter != null) {
      await saveCompleter!.future;
    }
    if (shouldThrow) throw Exception('Save failed');
    lastSaved = p;
    current = p;
    return p;
  }
}

void main() {
  test('fromJson defaults missing flags to true', () {
    final prefs = UserPreferences.fromJson({});
    expect(prefs.notifyOnDebtReminder, isTrue);
    expect(prefs.notifyOnSettlement, isTrue);
  });

  test('load exposes fetched preferences', () async {
    final fake = FakeUserPreferencesRepository(
      current: const UserPreferences(
        notifyOnDebtReminder: true,
        notifyOnSettlement: false,
      ),
    );
    final notifier = UserPreferencesNotifier(fake);
    await notifier.load();

    expect(notifier.state.value!.notifyOnSettlement, isFalse);
    expect(notifier.state.value!.notifyOnDebtReminder, isTrue);
  });

  test('setNotifyOnSettlement persists and returns true', () async {
    final fake = FakeUserPreferencesRepository(
      current: const UserPreferences(
        notifyOnDebtReminder: true,
        notifyOnSettlement: true,
      ),
    );
    final notifier = UserPreferencesNotifier(fake);
    await notifier.load();

    final result = await notifier.setNotifyOnSettlement(false);
    expect(result, isTrue);
    expect(fake.lastSaved!.notifyOnSettlement, isFalse);
    expect(notifier.state.value!.notifyOnSettlement, isFalse);
  });

  test('failed save reverts state and returns false', () async {
    final fake = FakeUserPreferencesRepository(
      current: const UserPreferences(
        notifyOnDebtReminder: true,
        notifyOnSettlement: true,
      ),
    );
    final notifier = UserPreferencesNotifier(fake);
    await notifier.load();

    fake.shouldThrow = true;
    final result = await notifier.setNotifyOnSettlement(false);
    expect(result, isFalse);
    expect(notifier.state.value!.notifyOnSettlement, isTrue);
  });

  test('second toggle while saving is rejected', () async {
    final fake = FakeUserPreferencesRepository();
    fake.saveCompleter = Completer<void>();
    final notifier = UserPreferencesNotifier(fake);
    await notifier.load();

    final firstFuture = notifier.setNotifyOnSettlement(true);
    final secondResult = await notifier.setNotifyOnDebtReminder(false);

    expect(secondResult, isFalse);
    expect(fake.saveCount, equals(1));

    fake.saveCompleter!.complete();
    final firstResult = await firstFuture;
    expect(firstResult, isTrue);
  });

  test('no state write after dispose', () async {
    final fake = FakeUserPreferencesRepository();
    fake.saveCompleter = Completer<void>();
    final notifier = UserPreferencesNotifier(fake);
    await notifier.load();

    final future = notifier.setNotifyOnSettlement(true);
    notifier.dispose();

    fake.saveCompleter!.complete();
    await expectLater(future, completes);
  });
}

