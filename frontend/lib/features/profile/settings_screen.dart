import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/state/app_sync.dart';
import '../../data/repositories/auth_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loading = true, _saving = false, _settlementPush = true;
  String? _error;
  int? _id;
  String _theme = 'SYSTEM', _language = 'VI';
  String t(String vi, String en) => tr(context, vi, en);
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _apply(Map<String, dynamic> data) {
    final mode = parseBackendThemeMode(data['theme']?.toString());
    final locale = parseBackendLocale(data['language']?.toString());
    _theme = mode.name.toUpperCase();
    _language = locale.languageCode.toUpperCase();
    _settlementPush = data['notifyOnSettlement'] != false;
    ref.read(themeModeProvider.notifier).state = mode;
    ref.read(localeProvider.notifier).state = locale;
  }

  Future<void> _load() async {
    if (_saving) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await AuthRepository().getCurrentUserId();
      final data = await fetchUserPreferences();
      if (!mounted) return;
      setState(() {
        _id = id;
        _apply(data);
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = t(
            'Không tải được cài đặt. Kiểm tra kết nối và thử lại.',
            'Could not load settings. Check your connection and retry.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(Map<String, dynamic> patch) async {
    if (_saving || _id == null) return;
    setState(() => _saving = true);
    try {
      final r = await dioClient.put('/v1/settings/user/$_id', data: patch);
      if (!mounted) return;
      ref.read(preferenceRevisionProvider.notifier).state++;
      setState(() => _apply(Map<String, dynamic>.from(r.data['data'] as Map)));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('Đã lưu cài đặt.', 'Settings saved.'))));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t('Không lưu được. Cài đặt cũ vẫn được giữ.',
                'Could not save. Previous settings are unchanged.'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(t('Cài đặt', 'Settings'))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: _load,
                              child: Text(t('Thử lại', 'Retry')))
                        ])))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_saving) const LinearProgressIndicator(),
                          Text(t('Giao diện', 'Appearance'),
                              style: Theme.of(context).textTheme.titleMedium),
                          Card(
                              child: Column(children: [
                            ListTile(
                                leading:
                                    const Icon(Icons.brightness_6_outlined),
                                title: Text(t('Chế độ màu', 'Color theme')),
                                subtitle: Text(t('Sáng, tối hoặc theo thiết bị',
                                    'Light, dark or system default'))),
                            for (final option in {
                              'SYSTEM': t('Theo thiết bị', 'System'),
                              'LIGHT': t('Sáng', 'Light'),
                              'DARK': t('Tối', 'Dark')
                            }.entries)
                              RadioListTile<String>(
                                  title: Text(option.value),
                                  value: option.key,
                                  groupValue: _theme,
                                  onChanged: _saving
                                      ? null
                                      : (v) {
                                          if (v != null) _save({'theme': v});
                                        }),
                            const Divider(),
                            ListTile(
                                leading: const Icon(Icons.language),
                                title: Text(t('Ngôn ngữ', 'Language')),
                                subtitle: Text(t(
                                    'Tiếng Anh hiện áp dụng cho điều hướng và cài đặt; một số nghiệp vụ vẫn tiếng Việt.',
                                    'English covers navigation and settings; some workflows remain Vietnamese.'))),
                            for (final option in {
                              'VI': 'Tiếng Việt',
                              'EN': 'English'
                            }.entries)
                              RadioListTile<String>(
                                  title: Text(option.value),
                                  value: option.key,
                                  groupValue: _language,
                                  onChanged: _saving
                                      ? null
                                      : (v) {
                                          if (v != null) _save({'language': v});
                                        }),
                          ])),
                          const SizedBox(height: 16),
                          Text(t('Thông báo', 'Notifications'),
                              style: Theme.of(context).textTheme.titleMedium),
                          Card(
                              child: SwitchListTile(
                                  secondary:
                                      const Icon(Icons.notifications_outlined),
                                  title: Text(t('Thông báo đẩy về thanh toán',
                                      'Payment push notifications')),
                                  subtitle: Text(t(
                                      'Không ảnh hưởng lịch sử thông báo trong ứng dụng. Cần bật quyền thông báo trên thiết bị.',
                                      'In-app history is unaffected. Device notification permission is required.')),
                                  value: _settlementPush,
                                  onChanged: _saving
                                      ? null
                                      : (v) =>
                                          _save({'notifyOnSettlement': v}))),
                          const SizedBox(height: 16),
                          Text(t('Thông tin chức năng', 'Feature information'),
                              style: Theme.of(context).textTheme.titleMedium),
                          Card(
                              child: Column(children: [
                            ListTile(
                                leading: const Icon(Icons.currency_exchange),
                                title: Text(t('Tiền tệ', 'Currency')),
                                subtitle: Text(t(
                                    'Giao diện khoản chi hiện hỗ trợ VND; không tự quy đổi tiền đã ghi.',
                                    'Expense entry currently supports VND; existing amounts are not converted.'))),
                            ListTile(
                                leading: const Icon(Icons.group_outlined),
                                title:
                                    Text(t('Quản lý nhóm', 'Group management')),
                                subtitle: Text(t(
                                    'Mở Nhóm → chọn nhóm → Cài đặt nhóm để sửa thông tin theo quyền.',
                                    'Open Groups → select a group → Group settings to edit authorized details.'))),
                            ListTile(
                                leading: const Icon(Icons.info_outline),
                                title: Text(t('Tính năng chưa hỗ trợ',
                                    'Not yet supported')),
                                subtitle: Text(t(
                                    'Khóa sinh trắc học, nhắc nợ tự động, phê duyệt chi, hạn mức và chốt sổ tự động chưa được thực thi đầy đủ. Các nút giả lập đã được ẩn.',
                                    'Biometrics, automatic reminders, expense approval, budgets and auto-closing are not fully implemented. Inactive switches are hidden.'))),
                          ])),
                        ]),
                  ),
      );
}
