// Trách nhiệm file: Xây dựng màn hình danh sách nhóm (groups screen) và điều phối tương tác người dùng với trạng thái nghiệp vụ.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/notification_screen.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';
import '../widgets/group_card.dart';
import '../widgets/group_card_skeleton.dart';
import '../widgets/empty_group_state.dart';
import '../widgets/error_state.dart';
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
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            GroupDetailScreen(group: group),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.n50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(userGroupsProvider.notifier).fetchGroups(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Top Header Row matching Figma: "Nhóm của tôi" + Search Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isSearching)
                      const Text(
                        'Nhóm của tôi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.n800,
                          letterSpacing: -0.5,
                        ),
                      )
                    else
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (val) => setState(
                            () => _searchQuery = val.trim().toLowerCase(),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm nhóm...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _isSearching = false;
                                  _searchQuery = '';
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    if (!_isSearching) const NotificationBell(),
                    if (!_isSearching)
                      IconButton(
                        icon: const Icon(
                          Icons.search_rounded,
                          size: 28,
                          color: AppColors.n800,
                        ),
                        tooltip: 'Tìm kiếm',
                        onPressed: () => setState(() => _isSearching = true),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Group List States
                Expanded(
                  child: groupsAsync.when(
                    data: (groups) {
                      final filteredGroups = _searchQuery.isEmpty
                          ? groups
                          : groups
                              .where(
                                (g) => g.name.toLowerCase().contains(
                                      _searchQuery,
                                    ),
                              )
                              .toList();

                      if (filteredGroups.isEmpty) {
                        if (_searchQuery.isNotEmpty) {
                          return LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
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
                        physics: const AlwaysScrollableScrollPhysics(),
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
                                    builder: (_) =>
                                        GroupSettingsScreen(group: group),
                                  ),
                                );
                              } else if (action == 'leave') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Rời khỏi nhóm'),
                                    content: Text(
                                      'Bạn có chắc chắn muốn rời nhóm "${group.name}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Hủy'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Rời nhóm'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await ref
                                        .read(userGroupsProvider.notifier)
                                        .leaveGroup(group.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Đã rời nhóm thành công',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () => ListView.builder(
                      itemCount: 4,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) =>
                          const GroupCardSkeleton(),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateGroupDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tạo nhóm mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
