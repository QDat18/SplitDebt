// Trách nhiệm file: Xây dựng màn hình cài đặt ngôn ngữ (LanguageSettingsScreen) theo chuẩn Apple HIG.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isEn = locale.languageCode == 'en';

    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: Text(context.tr('Ngôn ngữ', 'Language')),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s24),
        children: [
          GroupedSection(
            header: context.tr('Ngôn ngữ hiển thị', 'Display language'),
            footer: context.tr(
              'Giao diện ứng dụng sẽ chuyển đổi ngay lập tức giữa Tiếng Việt và Tiếng Anh.',
              'The app interface switches immediately between Vietnamese and English.',
            ),
            children: [
              GroupedTile(
                icon: Icons.language,
                title: 'Tiếng Việt',
                value: isEn ? null : context.tr('Mặc định', 'Default'),
                trailing: isEn
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check, color: AppColors.p500),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(localeProvider.notifier).setLocale(const Locale('vi'));
                },
              ),
              GroupedTile(
                icon: Icons.translate_rounded,
                title: 'English',
                trailing: isEn
                    ? const Icon(Icons.check, color: AppColors.p500)
                    : const SizedBox.shrink(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
