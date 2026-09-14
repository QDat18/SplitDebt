import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/dio_client.dart';
import '../../core/app/app_keys.dart';
import '../auth/data/auth_repository.dart';
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
    _messages = FirebaseMessaging.onMessage.listen((_) => _load());
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
      final response = await dioClient
          .get('/notifications', queryParameters: {'userId': user});
      if (!mounted) return;
      setState(() {
        _userId = user;
        _items = (response.data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Không tải được thông báo. Hãy thử lại.';
          _loading = false;
        });
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
    try {
      await dioClient.patch('/notifications/${item['id']}/read',
          queryParameters: {'userId': _userId});
      if (mounted) setState(() => item['isRead'] = true);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Chưa đánh dấu đã đọc được. Hãy thử lại.')));
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
              onPressed: _load,
              icon: const Icon(Icons.refresh))
        ]),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
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
                                : const Color(0xFFF0EDFF),
                            child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                leading: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                        item['type'] == 'SETTLEMENT_PAID'
                                            ? Icons.payments_outlined
                                            : Icons.notifications_none,
                                        color: const Color(0xFF6C5CE7),
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
                                        Text(_date(item['createdAt']), style: const TextStyle(fontSize: 12, color: Color(0xFF778092)))),
                                trailing: item['isRead'] == true ? null : const Icon(Icons.circle, size: 8, color: Color(0xFF6C5CE7)),
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
