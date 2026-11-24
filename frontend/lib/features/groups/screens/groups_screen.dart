// Trách nhiệm file: Xây dựng màn hình danh sách nhóm (groups screen) theo chuẩn Apple HIG / iOS Design.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../notifications/notification_screen.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';
import '../widgets/empty_group_state.dart';
import '../widgets/error_state.dart';
import '../widgets/group_card.dart';
import '../widgets/group_card_skeleton.dart';
import 'create_group_dialog.dart';
import 'group_detail_screen.dart';
import 'group_settings_screen.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateGroupDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => const CreateGroupDialog(),
    );
  }

  Future<void> _navigateToGroupDetail(GroupModel group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(group: group),
      ),
    );
  }

  Future<void> _confirmLeaveGroup(GroupModel group) async {
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Rời khỏi nhóm?'),
        content: Text('Bạn có chắc chắn muốn rời nhóm "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Rời nhóm',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(userGroupsProvider.notifier).leaveGroup(group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã rời nhóm thành công'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: const Text('Nhóm'),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          const NotificationBell(),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.n800,
            ),
            tooltip: _isSearching ? 'Đóng tìm kiếm' : 'Tìm kiếm nhóm',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.p500,
              size: 28,
            ),
            tooltip: 'Tạo nhóm mới',
            onPressed: _openCreateGroupDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(userGroupsProvider.notifier).fetchGroups(),
          child: Column(
            children: [
              // Thanh tìm kiếm phong cách iOS xuất hiện mượt mà khi mở tìm kiếm
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.n0,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppDimensions.shadowSm,
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 15, color: AppColors.n800),
                      onChanged: (val) => setState(
                        () => _searchQuery = val.trim().toLowerCase(),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo tên nhóm...',
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.n500),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.n500,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: AppColors.n500,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),

              // Group List States
              Expanded(
                child: groupsAsync.when(
                  data: (groups) {
                    final filteredGroups = _searchQuery.isEmpty
                        ? groups
                        : groups
                            .where(
                              (g) => g.name.toLowerCase().contains(_searchQuery),
                            )
                            .toList();

                    if (filteredGroups.isEmpty) {
                      if (_searchQuery.isNotEmpty) {
                        return LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'Không tìm thấy nhóm phù hợp với "$_searchQuery"',
                                    style: const TextStyle(
                                      color: AppColors.n600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return EmptyGroupState(
                        onCreateGroup: _openCreateGroupDialog,
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredGroups.length,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemBuilder: (context, index) {
                        final group = filteredGroups[index];
                        return GroupCard(
                          group: group,
                          onTap: () => _navigateToGroupDetail(group),
                          onActionSelected: (action) async {
                            if (action == 'settings') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroupSettingsScreen(group: group),
                                ),
                              );
                            } else if (action == 'leave') {
                              await _confirmLeaveGroup(group);
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () => ListView.builder(
                    itemCount: 4,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemBuilder: (context, index) => const GroupCardSkeleton(),
                  ),
                  error: (error, stack) => ErrorStateWidget(
                    errorMessage: error.toString().replaceAll(
                          'Exception: ',
                          '',
                        ),
                    onRetry: () =>
                        ref.read(userGroupsProvider.notifier).fetchGroups(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
