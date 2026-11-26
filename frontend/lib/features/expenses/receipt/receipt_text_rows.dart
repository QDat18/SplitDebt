// Trách nhiệm file: Gom các TextLine từ OCR thành từng hàng văn bản theo toạ độ Y và sắp từ trái sang phải.

class OcrLine {
  final String text;
  final double top;
  final double bottom;
  final double left;

  const OcrLine({
    required this.text,
    required this.top,
    required this.bottom,
    required this.left,
  });

  double get centerY => (top + bottom) / 2.0;
  double get height => (bottom - top).abs();
}

const int maxReceiptRows = 150;
const int maxReceiptRowLength = 200;

List<String> buildReceiptRows(List<OcrLine> lines) {
  final nonEmpty = lines.where((l) => l.text.trim().isNotEmpty).toList();
  if (nonEmpty.isEmpty) return const [];

  var totalHeight = 0.0;
  for (final l in nonEmpty) {
    totalHeight += l.height;
  }
  final avgHeight = totalHeight / nonEmpty.length;
  final threshold = avgHeight > 0 ? 0.5 * avgHeight : 1.0;

  final sorted = List<OcrLine>.from(nonEmpty)
    ..sort((a, b) => a.centerY.compareTo(b.centerY));

  final rowGroups = <List<OcrLine>>[];
  for (final line in sorted) {
    if (rowGroups.isEmpty) {
      rowGroups.add([line]);
      continue;
    }
    final currentGroup = rowGroups.last;
    final groupCenterY = currentGroup
            .map((e) => e.centerY)
            .reduce((a, b) => a + b) /
        currentGroup.length;

    if ((line.centerY - groupCenterY).abs() < threshold) {
      currentGroup.add(line);
    } else {
      rowGroups.add([line]);
    }
  }

  final rows = <String>[];
  for (final group in rowGroups) {
    group.sort((a, b) => a.left.compareTo(b.left));
    final joined = group.map((e) => e.text.trim()).join('  ').trim();
    if (joined.isEmpty) continue;
    final clamped = joined.length > maxReceiptRowLength
        ? joined.substring(0, maxReceiptRowLength)
        : joined;
    rows.add(clamped);
    if (rows.length >= maxReceiptRows) break;
  }

  return rows;
}

