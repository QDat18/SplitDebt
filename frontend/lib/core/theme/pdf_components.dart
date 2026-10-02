import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const pdfPurple = Color(0xFF6C5CE7);
const pdfGreen = Color(0xFF10BF8B);
const pdfRed = Color(0xFFFF5261);
const pdfMuted = Color(0xFF778092);
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
          color: const Color(0xFFEDEDF2),
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
                                          ? const Color(0xFF202127)
                                          : pdfMuted,
                                      fontWeight: selected == i
                                          ? FontWeight.w700
                                          : FontWeight.w500)))))))));
}
