// Trách nhiệm file: Màn hình Thông báo tương thích Light & Dark mode, an toàn khi Firebase tắt.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app/app_keys.dart';
import '../../core/network/dio_client.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/fintech_components.dart';
import '../../core/widgets/motion_kit.dart';
import '../../core/widgets/premium_shell.dart';
import '../../data/repositories/auth_repository.dart';
import 'push_notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _items = [];
  int? _userId;
  bool _loading = true;
  bool _enabling = false;
  String? _error;
  StreamSubscription<RemoteMessage>? _messages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _messages = FirebaseMessaging.onMessage.listen((_) => _load());
    } catch (_) {
      // Firebase có thể đang tắt ở môi trường local/web.
    }
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    _messages?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await AuthRepository().getCurrentUserId();
      final response = await dioClient.get(
        '/notifications',
        queryParameters: {'userId': user},
      );
      if (!mounted) return;
      setState(() {
        _userId = user;
        _items = (response.data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = tr(
            context,
            'Không tải được thông báo. Kiểm tra kết nối và thử lại.',
            'Could not load notifications. Check your connection and retry.',
          );
          _loading = false;
        });
      }
    }
  }

  Future<void> _enable() async {
    setState(() => _enabling = true);
    try {
      final push = PushNotificationService.instance;
      push.bindMessenger(scaffoldMessengerKey);
      await push.initialize();
      await push.subscribeToUser(await AuthRepository().getCurrentUserId());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Đã bật thông báo trên thiết bị này.',
                'Notifications enabled on this device.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Chưa bật được thông báo đẩy trên thiết bị này.',
                'Could not enable push notifications on this device.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enabling = false);
    }
  }

  Future<void> _read(Map<String, dynamic> item) async {
    if (item['isRead'] == true) return;
    try {
      await dioClient.patch(
        '/notifications/${item['id']}/read',
        queryParameters: {'userId': _userId},
      );
      if (mounted) setState(() => item['isRead'] = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Chưa đánh dấu đã đọc được. Hãy thử lại.',
                'Could not mark as read. Please retry.',
              ),
            ),
          ),
        );
      }
    }
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Thông báo', 'Notifications')),
        actions: [
          IconButton(
            tooltip: _enabling
                ? tr(context, 'Đang đăng ký...', 'Enabling...')
                : tr(
                    context,
                    'Bật thông báo trên thiết bị này',
                    'Enable push on this device',
                  ),
            onPressed: _enabling ? null : _enable,
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          IconButton(
            tooltip: tr(context, 'Tải lại', 'Refresh'),
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppDimensions.s16),
              child: Column(
                children: [
                  ShimmerBox(width: double.infinity, height: 72, radius: 12),
                  SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 72, radius: 12),
                ],
              ),
            )
          : RefreshIndicator(
              color: scheme.primary,
              onRefresh: _load,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.maxContentWidth,
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimensions.s16),
                    children: [
                      if (_error != null)
                        AppErrorState(
                          title: tr(context, 'Lỗi tải thông báo', 'Load error'),
                          message: _error!,
                          onRetry: _load,
                        )
                      else if (_items.isEmpty)
                        AppEmptyState(
                          icon: CupertinoIcons.bell,
                          title: tr(
                            context,
                            'Chưa có thông báo',
                            'No notifications',
                          ),
                          message: tr(
                            context,
                            'Các cập nhật về khoản chi và xác nhận thanh toán sẽ hiển thị tại đây.',
                            'Expense updates and settlement confirmations will appear here.',
                          ),
                        )
                      else
                        PremiumSurface(
                          padding: EdgeInsets.zero,
                          radius: AppDimensions.r12,
                          child: Column(
                            children: [
                              for (int i = 0; i < _items.length; i++) ...[
                                _notificationRow(_items[i], scheme),
                                if (i < _items.length - 1)
                                  const Divider(height: 1, indent: 64),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _notificationRow(Map<String, dynamic> item, ColorScheme scheme) {
    final isRead = item['isRead'] == true;
    final isSettlement = item['type'] == 'SETTLEMENT_PAID';

    return ColoredBox(
      color: isRead
          ? Colors.transparent
          : scheme.primary.withValues(alpha: 0.06),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSettlement
                ? Icons.payments_outlined
                : Icons.notifications_none_rounded,
            color: scheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          item['content']?.toString() ??
              item['title']?.toString() ??
              tr(context, 'Thông báo', 'Notification'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _date(item['createdAt']),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        trailing: isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _read(item),
      ),
    );
  }
}

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tr(context, 'Thông báo', 'Notifications'),
    icon: const Icon(Icons.notifications_none_rounded),
    onPressed: () =>
        Navigator.of(context).push(fintechRoute(const NotificationScreen())),
  );
}
