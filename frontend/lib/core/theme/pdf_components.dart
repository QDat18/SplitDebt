// Trách nhiệm file: Định nghĩa thành phần thiết kế PDF components dùng thống nhất trong toàn ứng dụng.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_colors.dart';

const pdfPurple = AppColors.p500;
const pdfGreen = AppColors.success;
const pdfRed = AppColors.error;
const pdfMuted = AppColors.n600;
String money(num value) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0)
        .format(value);

class PersonBadge extends StatelessWidget {
  final String name;
  final Color color;
  const PersonBadge(this.name, {super.key, this.color = pdfPurple});
  @override
  Widget build(BuildContext context) => CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: .09),
      child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.bold)));
}

class PdfTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const PdfTabs(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: AppColors.n200,
          borderRadius: BorderRadius.circular(10)),
      child: Row(
          children: List.generate(
              labels.length,
              (i) => Expanded(
                  child: Semantics(
                      button: true,
                      selected: selected == i,
                      child: InkWell(
                          onTap: () => onChanged(i),
                          child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                  color: selected == i
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7)),
                              child: Text(labels[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: selected == i
                                          ? AppColors.n800
                                          : pdfMuted,
                                      fontWeight: selected == i
                                          ? FontWeight.w700
                                          : FontWeight.w500)))))))));
}
