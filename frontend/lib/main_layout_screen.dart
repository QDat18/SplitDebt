// Trách nhiệm file: Khung điều hướng chính với thanh Tab Bar mờ chuẩn iOS (Cupertino) và đồng bộ dữ liệu realtime toàn ứng dụng.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app_keys.dart';
import 'core/state/app_sync.dart';
import 'core/widgets/adaptive_navigation_shell.dart';
import 'core/widgets/motion_kit.dart';
import 'data/repositories/auth_repository.dart';

import 'features/auth/login_screen.dart';
import 'features/expenses/create_expense_screen.dart';
import 'features/groups/dashboard_screen.dart';
import 'features/groups/providers/group_provider.dart';
import 'features/home/home_screen.dart';
import 'features/home/pdf_overview_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settlements/live_settlement_screen.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen>
    with WidgetsBindingObserver {
  int _index = 0;
  final Set<int> _visited = {0};
  Timer? _resumeTimer;
  bool _handlingExpiredSession = false;
  StreamSubscription<RemoteMessage>? _fcmSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restorePreferences());
    sessionExpiredSignal.addListener(_handleExpiredSession);
    appDataSyncSignal.addListener(_handleRealtimeSync);
    try {
      _fcmSub = FirebaseMessaging.onMessage.listen((_) {
        notifyDataChanged();
      });
    } catch (_) {
      // Firebase có thể đang tắt ở môi trường demo/local.
    }
  }

  Future<void> _restorePreferences() async {
    final revision = ref.read(preferenceRevisionProvider);
    try {
      final data = await fetchUserPreferences();
      if (!mounted ||
          _handlingExpiredSession ||
          revision != ref.read(preferenceRevisionProvider))
        return;
      ref.read(themeModeProvider.notifier).state = parseBackendThemeMode(
        data['theme']?.toString(),
      );
      ref.read(localeProvider.notifier).state = parseBackendLocale(
        data['language']?.toString(),
      );
    } catch (_) {
      /* device default until settings are reachable */
    }
  }

  void _handleRealtimeSync() {
    if (!mounted) return;
    ref
        .read(userGroupsProvider.notifier)
        .fetchGroups(silent: true, afterWrite: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _resumeTimer?.cancel();
      _resumeTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) notifyDataChanged();
      });
    }
  }

  void _handleExpiredSession() {
    if (!mounted || _handlingExpiredSession) return;
    _handlingExpiredSession = true;
    AuthRepository.clearCache();
    ref.read(themeModeProvider.notifier).state = ThemeMode.system;
    ref.read(localeProvider.notifier).state = const Locale('vi');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushAndRemoveUntil(fintechRoute(const LoginScreen()), (_) => false);
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    sessionExpiredSignal.removeListener(_handleExpiredSession);
    appDataSyncSignal.removeListener(_handleRealtimeSync);
    _fcmSub?.cancel();
    _resumeTimer?.cancel();
    super.dispose();
  }

  void _openCreateExpense() {
    Navigator.of(context).push(fintechRoute(const CreateExpenseScreen()));
  }

  void _openSettlement() {
    Navigator.of(context).push(fintechRoute(const GroupSettlementScreen()));
  }

  void _selectTab(int value) {
    if (_index == value) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = value;
      _visited.add(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationShell(
      selectedIndex: _index,
      labels: [
        tr(context, 'Trang chủ', 'Home'),
        tr(context, 'Nhóm', 'Groups'),
        tr(context, 'Lịch sử', 'History'),
        tr(context, 'Cá nhân', 'Profile'),
      ],
      addLabel: tr(context, 'Thêm khoản chi', 'Add expense'),
      onSelect: _selectTab,
      onQuickAdd: _openCreateExpense,
      child: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            onNavigateToCreateExpense: _openCreateExpense,
            onNavigateToSettlement: _openSettlement,
            onNavigateToGroups: () => _selectTab(1),
          ),
          if (_visited.contains(1))
            const HomeScreen()
          else
            const SizedBox.shrink(),
          if (_visited.contains(2))
            const OverviewScreen(key: ValueKey('history'), history: true)
          else
            const SizedBox.shrink(),
          if (_visited.contains(3))
            const ProfileScreen()
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
