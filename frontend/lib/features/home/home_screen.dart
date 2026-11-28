// Trách nhiệm file: Màn hình danh sách nhóm gọn gàng, hỗ trợ tìm kiếm, lọc công nợ, tương thích Light & Dark mode.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_sync.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/pdf_components.dart';
import '../../core/widgets/motion_kit.dart';
import '../../core/widgets/premium_shell.dart';
import '../groups/models/group_model.dart';
import '../groups/providers/group_provider.dart';
import '../groups/screens/create_group_dialog.dart';
import '../groups/screens/group_detail_screen.dart';
import '../groups/screens/group_settings_screen.dart';
import '../groups/widgets/empty_group_state.dart';
import '../groups/widgets/error_state.dart';
import '../groups/widgets/group_card.dart';
import '../groups/widgets/group_card_skeleton.dart';
import '../notifications/notification_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  int _balanceFilter = 0; // 0: All, 1: Owe, 2: Owed

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
    await Navigator.of(
      context,
    ).push(fintechRoute(GroupDetailScreen(group: group)));
  }

  Future<void> _handleGroupAction(GroupModel group, String action) async {
    if (action == 'settings') {
      await Navigator.push(
        context,
        fintechRoute(GroupSettingsScreen(group: group)),
      );
      return;
    }
    if (action != 'leave') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Rời khỏi nhóm', 'Leave group')),
        content: Text(
          tr(
            ctx,
            'Bạn có chắc chắn muốn rời nhóm "${group.name}"?',
            'Are you sure you want to leave "${group.name}"?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(ctx, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorFor(ctx),
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ctx, 'Rời nhóm', 'Leave')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(userGroupsProvider.notifier).leaveGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'Đã rời nhóm.', 'Left group.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: scheme.primary,
            onRefresh: () =>
                ref.read(userGroupsProvider.notifier).fetchGroups(),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.maxContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.s12),
                      Row(
                        children: [
                          if (!_isSearching) ...[
                            Expanded(
                              child: PremiumHeader(
                                eyebrow: '',
                                title: tr(context, 'Nhóm', 'Groups'),
                              ),
                            ),
                            const NotificationBell(),
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.search,
                                color: scheme.onSurface,
                              ),
                              tooltip: tr(context, 'Tìm kiếm', 'Search'),
                              onPressed: () =>
                                  setState(() => _isSearching = true),
                            ),
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.plus_circle,
                                color: scheme.primary,
                              ),
                              tooltip: tr(context, 'Tạo nhóm mới', 'New group'),
                              onPressed: _openCreateGroupDialog,
                            ),
                          ] else
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                onChanged: (val) => setState(
                                  () => _searchQuery = val.trim().toLowerCase(),
                                ),
                                decoration: InputDecoration(
                                  hintText: tr(
                                    context,
                                    'Tìm kiếm nhóm...',
                                    'Search groups...',
                                  ),
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: IconButton(
                                    tooltip: tr(context, 'Đóng', 'Close'),
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
                        ],
                      ),
                      const SizedBox(height: AppDimensions.s12),
                      PdfTabs(
                        labels: [
                          tr(context, 'Tất cả', 'All'),
                          tr(context, 'Cần trả', 'You owe'),
                          tr(context, 'Được nhận', 'Owed to you'),
                        ],
                        selected: _balanceFilter,
                        onChanged: (v) => setState(() => _balanceFilter = v),
                      ),
                      const SizedBox(height: AppDimensions.s12),
                      Expanded(
                        child: groupsAsync.when(
                          data: (groups) {
                            final filteredGroups = groups.where((g) {
                              if (_searchQuery.isNotEmpty &&
                                  !g.name.toLowerCase().contains(
                                    _searchQuery,
                                  )) {
                                return false;
                              }
                              final bal = g.userBalance ?? 0;
                              if (_balanceFilter == 1) return bal < 0;
                              if (_balanceFilter == 2) return bal > 0;
                              return true;
                            }).toList();

                            if (groups.isEmpty) {
                              return EmptyGroupState(
                                onCreateGroup: _openCreateGroupDialog,
                              );
                            }

                            if (filteredGroups.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    tr(
                                      context,
                                      'Không có nhóm phù hợp với bộ lọc hiện tại.',
                                      'No groups match the current filter.',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 96),
                              itemCount: filteredGroups.length,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final group = filteredGroups[index];
                                return GroupCard(
                                  group: group,
                                  onTap: () => _navigateToGroupDetail(group),
                                  onActionSelected: (action) =>
                                      _handleGroupAction(group, action),
                                );
                              },
                            );
                          },
                          loading: () => ListView.builder(
                            itemCount: 4,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (_, __) => const GroupCardSkeleton(),
                          ),
                          error: (error, _) => ErrorStateWidget(
                            errorMessage: error.toString().replaceAll(
                              'Exception: ',
                              '',
                            ),
                            onRetry: () => ref
                                .read(userGroupsProvider.notifier)
                                .fetchGroups(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
