import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

class UserPreferences {
  final bool notifyOnDebtReminder;
  final bool notifyOnSettlement;

  const UserPreferences({
    this.notifyOnDebtReminder = true,
    this.notifyOnSettlement = true,
  });

  UserPreferences copyWith({
    bool? notifyOnDebtReminder,
    bool? notifyOnSettlement,
  }) {
    return UserPreferences(
      notifyOnDebtReminder: notifyOnDebtReminder ?? this.notifyOnDebtReminder,
      notifyOnSettlement: notifyOnSettlement ?? this.notifyOnSettlement,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notifyOnDebtReminder: json['notifyOnDebtReminder'] as bool? ?? true,
      notifyOnSettlement: json['notifyOnSettlement'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifyOnDebtReminder': notifyOnDebtReminder,
      'notifyOnSettlement': notifyOnSettlement,
    };
  }
}

abstract class UserPreferencesRepository {
  Future<UserPreferences> fetch();
  Future<UserPreferences> save(UserPreferences p);
}

class DioUserPreferencesRepository implements UserPreferencesRepository {
  final Dio dio;

  DioUserPreferencesRepository(this.dio);

  @override
  Future<UserPreferences> fetch() async {
    final response = await dio.get('/settings/user/me');
    return UserPreferences.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<UserPreferences> save(UserPreferences p) async {
    final response = await dio.put('/settings/user/me', data: p.toJson());
    return UserPreferences.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }
}

class UserPreferencesNotifier
    extends StateNotifier<AsyncValue<UserPreferences>> {
  final UserPreferencesRepository repository;

  UserPreferencesNotifier(this.repository)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await repository.fetch();
      state = AsyncValue.data(prefs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> setNotifyOnDebtReminder(bool v) async {
    final oldState = state;
    final current = state.value ?? const UserPreferences();
    final updated = current.copyWith(notifyOnDebtReminder: v);
    state = AsyncValue.data(updated);

    try {
      final saved = await repository.save(updated);
      state = AsyncValue.data(saved);
      return true;
    } catch (e) {
      state = oldState;
      return false;
    }
  }

  Future<bool> setNotifyOnSettlement(bool v) async {
    final oldState = state;
    final current = state.value ?? const UserPreferences();
    final updated = current.copyWith(notifyOnSettlement: v);
    state = AsyncValue.data(updated);

    try {
      final saved = await repository.save(updated);
      state = AsyncValue.data(saved);
      return true;
    } catch (e) {
      state = oldState;
      return false;
    }
  }
}

final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((ref) {
  return DioUserPreferencesRepository(dioClient);
});

final userPreferencesProvider = StateNotifierProvider.autoDispose<
    UserPreferencesNotifier, AsyncValue<UserPreferences>>((ref) {
  final repo = ref.watch(userPreferencesRepositoryProvider);
  return UserPreferencesNotifier(repo);
});

