// Trách nhiệm file: Màn hình Cài đặt chuẩn Mobile: Giao diện (Sáng/Tối/Hệ thống), Ngôn ngữ (VI/EN) và Thông báo đẩy thực tế.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/fintech_components.dart';
import '../../core/widgets/premium_shell.dart';
import '../../data/repositories/auth_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _settlementPush = true;
  String? _error;
  int? _id;
  String _theme = 'SYSTEM';
  String _language = 'VI';

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
      if (mounted) {
        setState(
          () => _error = t(
            'Không tải được cài đặt. Kiểm tra kết nối và thử lại.',
            'Could not load settings. Check your connection and retry.',
          ),
        );
      }
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
        SnackBar(content: Text(t('Đã lưu cài đặt.', 'Settings saved.'))),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t(
                'Không lưu được. Cài đặt cũ vẫn được giữ.',
                'Could not save. Previous settings are unchanged.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _optionRow({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      enabled: onTap != null,
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: scheme.onSurface,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: scheme.primary)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeOptions = <String, String>{
      'SYSTEM': t('Theo hệ thống', 'System default'),
      'LIGHT': t('Sáng', 'Light'),
      'DARK': t('Tối', 'Dark'),
    };
    const languageOptions = <String, String>{
      'VI': 'Tiếng Việt',
      'EN': 'English',
    };

    return Scaffold(
      appBar: AppBar(title: Text(t('Cài đặt', 'Settings'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(AppDimensions.s20),
              child: Center(
                child: AppErrorState(
                  title: t('Lỗi tải cài đặt', 'Load error'),
                  message: _error!,
                  onRetry: _load,
                ),
              ),
            )
          : RefreshIndicator(
              color: scheme.primary,
              onRefresh: _load,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimensions.s16),
                    children: [
                      if (_saving) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: AppDimensions.s12),
                      ],
                      SectionLabel(title: t('Giao diện', 'Appearance')),
                      const SizedBox(height: AppDimensions.s8),
                      PremiumSurface(
                        padding: EdgeInsets.zero,
                        radius: AppDimensions.r12,
                        child: Column(
                          children: [
                            for (int i = 0; i < themeOptions.length; i++) ...[
                              _optionRow(
                                label: themeOptions.values.elementAt(i),
                                selected:
                                    _theme == themeOptions.keys.elementAt(i),
                                onTap: _saving
                                    ? null
                                    : () => _save({
                                        'theme': themeOptions.keys.elementAt(i),
                                      }),
                              ),
                              if (i < themeOptions.length - 1)
                                const Divider(height: 1, indent: 16),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.s20),
                      SectionLabel(title: t('Ngôn ngữ', 'Language')),
                      const SizedBox(height: AppDimensions.s8),
                      PremiumSurface(
                        padding: EdgeInsets.zero,
                        radius: AppDimensions.r12,
                        child: Column(
                          children: [
                            for (
                              int i = 0;
                              i < languageOptions.length;
                              i++
                            ) ...[
                              _optionRow(
                                label: languageOptions.values.elementAt(i),
                                selected:
                                    _language ==
                                    languageOptions.keys.elementAt(i),
                                onTap: _saving
                                    ? null
                                    : () => _save({
                                        'language': languageOptions.keys
                                            .elementAt(i),
                                      }),
                              ),
                              if (i < languageOptions.length - 1)
                                const Divider(height: 1, indent: 16),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.s20),
                      SectionLabel(title: t('Thông báo', 'Notifications')),
                      const SizedBox(height: AppDimensions.s8),
                      PremiumSurface(
                        padding: EdgeInsets.zero,
                        radius: AppDimensions.r12,
                        child: SwitchListTile(
                          secondary: const Icon(Icons.notifications_outlined),
                          title: Text(
                            t(
                              'Thông báo đẩy về thanh toán',
                              'Payment push notifications',
                            ),
                          ),
                          subtitle: Text(
                            t(
                              'Cần cấp quyền thông báo trên thiết bị. Lịch sử thông báo trong ứng dụng không bị ảnh hưởng.',
                              'Requires device notification permission. In-app history is unaffected.',
                            ),
                          ),
                          value: _settlementPush,
                          onChanged: _saving
                              ? null
                              : (v) => _save({'notifyOnSettlement': v}),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.s20),
                      SectionLabel(title: t('Tiền tệ', 'Currency')),
                      const SizedBox(height: AppDimensions.s8),
                      PremiumSurface(
                        padding: EdgeInsets.zero,
                        radius: AppDimensions.r12,
                        child: ListTile(
                          leading: const Icon(Icons.currency_exchange),
                          title: Text(t('Đơn vị tiền tệ', 'Default currency')),
                          subtitle: Text(
                            t(
                              'VND (₫) — các khoản chi hiện được ghi nhận bằng VND.',
                              'VND (₫) — expenses are currently recorded in VND.',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
