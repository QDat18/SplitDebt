// Trách nhiệm file: Quản lý và cung cấp trạng thái group provider cho widget bằng Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/group_model.dart';
import '../models/group_member_model.dart';

class GroupListNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  GroupListNotifier() : super(const AsyncValue.loading()) {
    fetchGroups();
  }

  Future<void>? _inFlight;
  bool _repeat = false;
  Future<void> fetchGroups({bool silent = false, bool afterWrite = false}) {
    if (_inFlight != null) {
      if (afterWrite) _repeat = true;
      return _inFlight!;
    }
    final future = _fetchLoop(silent);
    _inFlight = future;
    return future;
  }

  Future<void> _fetchLoop(bool silent) async {
    try {
      do {
        _repeat = false;
        if (!mounted) return;
        if (!state.hasValue && !silent) state = const AsyncValue.loading();
        try {
          final data = await ApiClient.get('/groups') as List;
          if (!mounted) return;
          state = AsyncValue.data(
            data
                .map(
                  (json) => GroupModel.fromJson(
                    Map<String, dynamic>.from(json as Map),
                  ),
                )
                .toList(),
          );
        } catch (e, st) {
          if (mounted && !state.hasValue) state = AsyncValue.error(e, st);
        }
      } while (_repeat);
    } finally {
      _inFlight = null;
    }
  }

  Future<GroupModel> createGroup(String name, String? description) async {
    try {
      final res = await ApiClient.post('/groups', {
        'name': name,
        'description': description ?? '',
      });
      final newGroup = GroupModel.fromJson(res as Map<String, dynamic>);
      await fetchGroups(afterWrite: true);
      return newGroup;
    } catch (e) {
      rethrow;
    }
  }

  Future<GroupModel> updateGroup(
    String groupId,
    String name,
    String? description,
  ) async {
    try {
      final res = await ApiClient.put('/groups/$groupId', {
        'name': name,
        'description': description ?? '',
      });
      final updatedGroup = GroupModel.fromJson(res as Map<String, dynamic>);
      await fetchGroups(afterWrite: true);
      return updatedGroup;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await ApiClient.delete('/groups/$groupId');
      await fetchGroups(afterWrite: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await ApiClient.delete('/groups/$groupId/members/me');
      await fetchGroups(afterWrite: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<GroupMemberModel> addMember(
    String groupId,
    String email, {
    String role = 'MEMBER',
  }) async {
    try {
      final res = await ApiClient.post('/groups/$groupId/members', {
        'email': email,
        'role': role,
      });
      await fetchGroups(afterWrite: true);
      return GroupMemberModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeMember(String groupId, String memberUserId) async {
    try {
      await ApiClient.delete('/groups/$groupId/members/$memberUserId');
      await fetchGroups(afterWrite: true);
    } catch (e) {
      rethrow;
    }
  }
}

final userGroupsProvider =
    StateNotifierProvider.autoDispose<
      GroupListNotifier,
      AsyncValue<List<GroupModel>>
    >((ref) {
      return GroupListNotifier();
    });

final groupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMemberModel>, String>((ref, groupId) async {
      final List<dynamic> data = await ApiClient.get(
        '/groups/$groupId/members',
      );
      return data
          .map(
            (json) => GroupMemberModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    });
