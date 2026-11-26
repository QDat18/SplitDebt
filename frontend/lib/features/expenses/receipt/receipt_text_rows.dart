// Trách nhiệm file: Gom các TextLine từ OCR thành từng hàng văn bản theo toạ độ Y và sắp từ trái sang phải.

import 'dart:math' as math;

class OcrPoint {
  final double x;
  final double y;

  const OcrPoint(this.x, this.y);
}

class OcrLine {
  final String text;
  final double top;
  final double bottom;
  final double left;
  final List<OcrPoint>? corners;

  const OcrLine({
    required this.text,
    required this.top,
    required this.bottom,
    required this.left,
    this.corners,
  });

  double get centerY => (top + bottom) / 2.0;
  double get height => (bottom - top).abs();
}

const int maxReceiptRows = 150;
const int maxReceiptRowLength = 200;

List<OcrLine> deskewLines(List<OcrLine> lines) {
  var linesWithCorners = 0;
  final angles = <double>[];
  for (final l in lines) {
    final c = l.corners;
    if (c == null || c.length < 2) continue;
    linesWithCorners++;
    if (l.text.trim().length < 4) continue;
    var angle = math.atan2(c[1].y - c[0].y, c[1].x - c[0].x);
    if ((angle + math.pi).abs() < 1e-6) {
      angle = math.pi;
    }
    angles.add(angle);
  }

  if (linesWithCorners < 3 || angles.isEmpty) {
    return lines;
  }

  angles.sort();
  final mid = angles.length ~/ 2;
  final medianAngle = angles.length.isOdd
      ? angles[mid]
      : (angles[mid - 1] + angles[mid]) / 2.0;

  if (medianAngle.abs() < 3.0 * math.pi / 180.0) {
    return lines;
  }

  final cosA = math.cos(-medianAngle);
  final sinA = math.sin(-medianAngle);

  return lines.map((l) {
    final c = l.corners;
    if (c == null || c.isEmpty) return l;
    final rotated = c
        .map((p) => OcrPoint(p.x * cosA - p.y * sinA, p.x * sinA + p.y * cosA))
        .toList();
    var minX = rotated.first.x;
    var minY = rotated.first.y;
    var maxY = rotated.first.y;
    for (var i = 1; i < rotated.length; i++) {
      final p = rotated[i];
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    return OcrLine(
      text: l.text,
      top: minY,
      bottom: maxY,
      left: minX,
      corners: rotated,
    );
  }).toList();
}

List<String> buildReceiptRows(List<OcrLine> lines) {
  final nonEmpty =
      deskewLines(lines).where((l) => l.text.trim().isNotEmpty).toList();
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

