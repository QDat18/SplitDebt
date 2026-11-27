// Trách nhiệm file: Hiển thị toàn văn Chính sách quyền riêng tư hoặc Điều khoản sử dụng theo chuẩn HIG.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import 'legal_texts.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocType document;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = document == LegalDocType.privacy;
    final title = isPrivacy
        ? 'Chính sách quyền riêng tư'
        : 'Điều khoản sử dụng';
    final version = isPrivacy ? kPrivacyVersion : kTermsVersion;
    final sections = isPrivacy ? kPrivacySections : kTermsSections;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.n50,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.n50,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.s16),
        itemCount: sections.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.s16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.all(AppDimensions.s16),
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: AppDimensions.radius12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.n900,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s8),
                  Text(
                    'Phiên bản: $version',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.n600,
                    ),
                  ),
                ],
              ),
            );
          }

          final section = sections[index - 1];
          return Container(
            padding: const EdgeInsets.all(AppDimensions.s16),
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: AppDimensions.radius12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n900,
                  ),
                ),
                const SizedBox(height: AppDimensions.s8),
                for (var i = 0; i < section.paragraphs.length; i++) ...[
                  Text(
                    section.paragraphs[i],
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 1.45,
                      color: AppColors.n800,
                    ),
                  ),
                  if (i < section.paragraphs.length - 1)
                    const SizedBox(height: AppDimensions.s8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

