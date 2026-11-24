// Trách nhiệm file: Xây dựng màn hình notification screen và điều phối tương tác người dùng với trạng thái nghiệp vụ.

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/dio_client.dart';
import '../../core/app/app_keys.dart';
import '../../core/navigation/route_observer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/visible_poller.dart';
import '../../data/repositories/auth_repository.dart';
import 'notification_merge.dart';
import 'push_notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver, RouteAware {
  List<Map<String, dynamic>> _items = [];
  int? _userId;
  bool _loading = true;
  bool _enabling = false;
  String? _error;
  StreamSubscription<RemoteMessage>? _messages;
  late final VisiblePoller _poller;
  final Set<Object> _pendingReadIds = {};
  bool _subscribedToRoute = false;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poller = VisiblePoller(
      interval: const Duration(seconds: 20),
      onTick: () => _load(silent: true),
    );
    _poller.start();
    _messages = FirebaseMessaging.onMessage.listen((_) => _load(silent: true));
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribedToRoute) {
      final route = ModalRoute.of(context);
      if (route != null) {
        appRouteObserver.subscribe(this, route);
        _subscribedToRoute = true;
      }
    }
  }

  @override
  void didPushNext() {
    _poller.setCovered(true);
  }

  @override
  void didPopNext() {
    _poller.setCovered(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _poller.onLifecycle(state);
    if (state == AppLifecycleState.resumed && !_poller.isCovered) {
      _load(silent: true);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _poller.stop();
    _messages?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final version = ++_version;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final user = await AuthRepository().getCurrentUserId();
      final response = await dioClient
          .get('/notifications', queryParameters: {'userId': user});
      if (!mounted || version != _version) return;
      final rawList = (response.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      for (final item in rawList) {
        if (item['isRead'] == true) {
          _pendingReadIds.remove(item['id']);
        }
      }

      final mergedList = applyPendingReads(rawList, _pendingReadIds);

      setState(() {
        _userId = user;
        _items = mergedList;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || version != _version) return;
      if (silent) {
        debugPrint('NotificationScreen silent load error: $e');
        final hasData = _items.isNotEmpty || _userId != null;
        setState(() {
          if (!hasData) {
            _error = 'Không tải được thông báo. Hãy thử lại.';
          }
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Không tải được thông báo. Hãy thử lại.';
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã bật thông báo trên thiết bị này.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chưa bật được thông báo: $error')));
    } finally {
      if (mounted) setState(() => _enabling = false);
    }
  }

  Future<void> _read(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id != null) {
      _pendingReadIds.add(id);
    }
    setState(() => item['isRead'] = true);
    try {
      await dioClient.patch('/notifications/$id/read',
          queryParameters: {'userId': _userId});
    } catch (_) {
      if (id != null) {
        _pendingReadIds.remove(id);
      }
      if (mounted) {
        setState(() => item['isRead'] = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Chưa đánh dấu đã đọc được. Hãy thử lại.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Thông báo'), actions: [
          IconButton(
              tooltip: _enabling
                  ? 'Đang đăng ký...'
                  : 'Bật thông báo trên thiết bị này',
              onPressed: _enabling ? null : _enable,
              icon: const Icon(Icons.notifications_active_outlined)),
          IconButton(
              tooltip: 'Tải lại',
              onPressed: () => _load(silent: false),
              icon: const Icon(Icons.refresh))
        ]),
        body: (_loading && _items.isEmpty && _userId == null)
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _load(silent: true),
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_error != null)
                        Text(_error!)
                      else if (_items.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                                'Chưa có thông báo. Các cập nhật thanh toán sẽ xuất hiện tại đây.',
                                textAlign: TextAlign.center)),
                      for (final item in _items)
                        Card(
                            color: item['isRead'] == true
                                ? Colors.white
                                : AppColors.p50,
                            child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                leading: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                        item['type'] == 'SETTLEMENT_PAID'
                                            ? Icons.payments_outlined
                                            : Icons.notifications_none,
                                        color: AppColors.p500,
                                        size: 22)),
                                title:
                                    Text(item['content']?.toString() ?? item['title']?.toString() ?? 'Thông báo',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: item['isRead'] == true
                                                ? FontWeight.w500
                                                : FontWeight.w700)),
                                subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child:
                                        Text(_date(item['createdAt']), style: const TextStyle(fontSize: 12, color: AppColors.n600))),
                                trailing: item['isRead'] == true ? null : const Icon(Icons.circle, size: 8, color: AppColors.p500),
                                onTap: () => _read(item))),
                    ])),
      );
  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }
}

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
      tooltip: 'Thông báo',
      icon: const Icon(Icons.notifications_none_rounded),
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const NotificationScreen())));
}
