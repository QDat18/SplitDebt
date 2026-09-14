import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/group_model.dart';
import '../../auth/data/auth_repository.dart';
import '../models/group_member_model.dart';

class GroupListNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  GroupListNotifier() : super(const AsyncValue.loading()) {
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    state = const AsyncValue.loading();
    try {
      final List<dynamic> data = await ApiClient.get('/groups');
      final groups = data
          .map((json) => GroupModel.fromJson(json as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(groups);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<GroupModel> createGroup(String name, String? description) async {
    try {
      final res = await ApiClient.post('/groups', {
        'name': name,
        'description': description ?? '',
      });
      final newGroup = GroupModel.fromJson(res as Map<String, dynamic>);
      await fetchGroups();
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
      await fetchGroups();
      return updatedGroup;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await ApiClient.delete('/groups/$groupId');
      await fetchGroups();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await ApiClient.delete('/groups/$groupId/members/me');
      await fetchGroups();
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
      await fetchGroups();
      return GroupMemberModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeMember(String groupId, String memberUserId) async {
    try {
      await ApiClient.delete('/groups/$groupId/members/$memberUserId');
      await fetchGroups();
    } catch (e) {
      rethrow;
    }
  }
}

final userGroupsProvider = StateNotifierProvider.autoDispose<GroupListNotifier,
    AsyncValue<List<GroupModel>>>((
  ref,
) {
  return GroupListNotifier();
});

final groupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMemberModel>, String>((ref, groupId) async {
  final List<dynamic> data = await ApiClient.get('/groups/$groupId/members');
  return data
      .map((json) => GroupMemberModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

final _currentAccountId = FutureProvider.autoDispose<int>(
    (ref) => AuthRepository().getCurrentUserId());
final groupNetBalanceProvider =
    FutureProvider.autoDispose.family<double, String>((ref, groupId) async {
  final user = await ref.watch(_currentAccountId.future);
  final result = await ApiClient.get('/groups/$groupId/debts?userId=$user');
  return (result['totalToReceive'] as num? ?? 0).toDouble() -
      (result['totalToPay'] as num? ?? 0).toDouble();
});
