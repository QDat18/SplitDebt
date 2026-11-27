// Trách nhiệm file: Định nghĩa thành phần thiết kế dùng thống nhất (tiền tệ, badge thành viên, iOS Sliding Segmented Control).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'app_colors.dart';

const pdfPurple = AppColors.p500;
const pdfGreen = AppColors.success;
const pdfRed = AppColors.error;
const pdfMuted = AppColors.n600;

String money(num value) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(value);

class PersonBadge extends StatelessWidget {
  final String name;
  final Color color;
  final double radius;

  const PersonBadge(
    this.name, {
    super.key,
    this.color = pdfPurple,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final glyph =
        trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: .14),
      ),
      child: Center(
        child: Text(
          glyph,
          style: TextStyle(
            color: color,
            fontSize: radius * 0.72,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Segmented control chuẩn iOS (UISegmentedControl) với con trượt mượt, hỗ trợ Light & Dark mode.
class PdfTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const PdfTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final safeSelected = selected.clamp(0, labels.length - 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA);
    final thumbColor = isDark ? const Color(0xFF3A3A3C) : Colors.white;
    final activeText = isDark ? Colors.white : const Color(0xFF000000);
    final inactiveText =
        isDark ? const Color(0xFF98989F) : const Color(0xFF636366);

    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: safeSelected * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isDark
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final isActive = safeSelected == i;
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: isActive,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (i != safeSelected) {
                            HapticFeedback.selectionClick();
                            onChanged(i);
                          }
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 160),
                            style: TextStyle(
                              fontSize: 13,
                              color: isActive ? activeText : inactiveText,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w500,
                            ),
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
