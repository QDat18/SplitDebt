// Trách nhiệm file: Chuẩn hoá chuỗi tiếng Việt và bóc tách các token tiền tệ (VND) từ một dòng văn bản OCR.

const String _vietnameseChars =
    'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
    'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ';
const String _asciiChars =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

String normalizeForMatch(String input) {
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    final idx = _vietnameseChars.indexOf(ch);
    buffer.write(idx >= 0 ? _asciiChars[idx] : ch.toLowerCase());
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

class MoneyToken {
  final int value;
  final int start;
  final int end;

  const MoneyToken({
    required this.value,
    required this.start,
    required this.end,
  });
}

final RegExp _candidateMoneyRegex = RegExp(
  r'(?<![0-9A-Za-z]|\d[.,])([0-9OoIlSB]{1,3}(?:[.,][0-9OoIlSB]{3})+|[0-9OoIlSB]{1,3}(?: [0-9OoIlSB]{3})+|[0-9OoIlSB]{1,6}[kK]|[0-9OoIlSB]{4,9}|[0-9]{1,3}[.,][0-9]{1,2})(?:\s*(?:đ|d|vnd|vnđ))?(?![0-9A-Za-z]|[.,]\d)',
  caseSensitive: false,
);

String? _fixOcrNumeric(String raw) {
  var hasDigit = false;
  final sb = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final ch = raw[i];
    if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
      hasDigit = true;
      sb.write(ch);
    } else if (ch == 'O' || ch == 'o') {
      sb.write('0');
    } else if (ch == 'l' || ch == 'I') {
      sb.write('1');
    } else if (ch == 'S') {
      sb.write('5');
    } else if (ch == 'B') {
      sb.write('8');
    } else if (ch == '.' || ch == ',' || ch == ' ') {
      sb.write(ch);
    } else {
      return null;
    }
  }
  return hasDigit ? sb.toString() : null;
}

final RegExp _dateLikeRegex = RegExp(
  r'(?<!\d)\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}(?!\d)',
);
final RegExp _phoneKeywordRegex = RegExp(
  r'\b(?:dt|sdt|tel|phone|hotline|dien thoai)\b',
);
final RegExp _standardPhoneRegex = RegExp(
  r'(?<![0-9A-Za-z.,])(?:\+84[\s.-]?[1-9]\d{1,2}[ .-]?\d{3,4}[ .-]?\d{3,4}|0\d{1,3}[ .-]?\d{3,4}[ .-]?\d{3,4}(?:-\d{3,6})?|0\d{9,10}(?:-\d{3,6})?|(?:1800|1900)[ .]\d{4})(?![0-9A-Za-z.,])',
);

List<MoneyToken>? trySplitSpaceMoney(String fixed, int baseOffset) {
  final groups = fixed.split(' ');
  if (groups.length < 3) return null;

  List<MoneyToken>? bestTwoPart(List<String> g, int offset, {int? expectedQty}) {
    if (g.length < 2) return null;
    List<MoneyToken>? fallback;
    var groupStart = offset;
    for (var cut = 1; cut < g.length; cut++) {
      groupStart += g[cut - 1].length + 1;
      if (g[0].startsWith('0') || g[cut].startsWith('0')) continue;
      final leftVal = int.tryParse(g.sublist(0, cut).join());
      final rightVal = int.tryParse(g.sublist(cut).join());
      if (leftVal == null || rightVal == null) continue;
      if (leftVal < 1000 || leftVal > 100000000) continue;
      if (rightVal < 1000 || rightVal > 100000000) continue;

      final leftEnd = groupStart - 1;
      final rightEnd = offset + g.join(' ').length;
      final pair = [
        MoneyToken(value: leftVal, start: offset, end: leftEnd),
        MoneyToken(value: rightVal, start: groupStart, end: rightEnd),
      ];

      if (expectedQty != null && (expectedQty * leftVal - rightVal).abs() <= 1000) {
        return pair;
      }
      if (rightVal >= leftVal && rightVal % leftVal == 0 && (rightVal ~/ leftVal) <= 20) {
        return pair;
      }
      fallback ??= pair;
    }
    return fallback;
  }

  // Prefer 2-part split where right is a small integer multiple of left.
  final twoPart = bestTwoPart(groups, baseOffset);
  if (twoPart != null &&
      twoPart[1].value >= twoPart[0].value &&
      twoPart[1].value % twoPart[0].value == 0 &&
      (twoPart[1].value ~/ twoPart[0].value) <= 20) {
    return twoPart;
  }

  // If leading group is a small quantity (1..99), try splitting the rest.
  final qty = int.tryParse(groups[0]);
  if (qty != null && qty >= 1 && qty <= 99 && groups.length >= 3) {
    final restOffset = baseOffset + groups[0].length + 1;
    final withQty = bestTwoPart(groups.sublist(1), restOffset, expectedQty: qty);
    if (withQty != null) return withQty;
  }

  return twoPart;
}

List<MoneyToken> parseMoneyTokens(String row) {
  final tokens = <MoneyToken>[];
  var sanitizedRow = row.replaceAllMapped(
    _dateLikeRegex,
    (m) => ' ' * (m.end - m.start),
  );
  final hasPhoneKeyword = _phoneKeywordRegex.hasMatch(normalizeForMatch(row));
  sanitizedRow = sanitizedRow.replaceAllMapped(_standardPhoneRegex, (m) {
    if (hasPhoneKeyword) return ' ' * (m.end - m.start);
    final prefix = normalizeForMatch(row.substring(0, m.start));
    if (RegExp(r'[a-z]{2,}').hasMatch(prefix)) {
      return m.group(0)!;
    }
    return ' ' * (m.end - m.start);
  });
  sanitizedRow = sanitizedRow.replaceAllMapped(
    RegExp(r'(?<![0-9A-Za-z])([0-9OoIlSB]{1,3}(?:,[0-9OoIlSB]{3})+)\.00(?![0-9A-Za-z.,])'),
    (m) => '${m.group(1)!}   ',
  );
  sanitizedRow = sanitizedRow.replaceAllMapped(
    RegExp(r'(?<![0-9A-Za-z])([0-9OoIlSB]{1,3}(?:\.[0-9OoIlSB]{3})+),00(?![0-9A-Za-z.,])'),
    (m) => '${m.group(1)!}   ',
  );
  sanitizedRow = sanitizedRow.replaceAllMapped(
    RegExp(r'(?<![0-9A-Za-z.,])(?:\d{10,14}|(?!\d+000(?![0-9]))\d{8,9})(?![0-9A-Za-z.,])'),
    (m) => ' ' * (m.end - m.start),
  );
  sanitizedRow = sanitizedRow.replaceAllMapped(
    RegExp(r'\.{2,}|(?<=\d)[.,-]+(?=\s|$)'),
    (m) => ' ' * (m.end - m.start),
  );

  for (final match in _candidateMoneyRegex.allMatches(sanitizedRow)) {
    final core = match.group(1);
    if (core == null || core.isEmpty) continue;

    // Reject decimal numbers like 12.5 or 12,50
    if (RegExp(r'^\d+[.,]\d{1,2}$').hasMatch(core)) {
      continue;
    }

    var isK = false;
    var numericPart = core;
    if (core.endsWith('k') || core.endsWith('K')) {
      isK = true;
      numericPart = core.substring(0, core.length - 1);
    }

    final fixed = _fixOcrNumeric(numericPart);
    if (fixed == null) continue;

    final digitsOnly = fixed.replaceAll(RegExp(r'[., ]'), '');
    if (!fixed.contains(RegExp(r'[., ]')) && digitsOnly.startsWith('0')) {
      continue;
    }
    final parsed = int.tryParse(digitsOnly);
    if (parsed == null) continue;

    final value = isK ? parsed * 1000 : parsed;
    if (value > 100000000 && !isK && fixed.contains(' ')) {
      final split = trySplitSpaceMoney(fixed, match.start);
      if (split != null) {
        tokens.addAll(split);
        continue;
      }
    }
    if (value < 1000 || value > 100000000) continue;

    tokens.add(MoneyToken(value: value, start: match.start, end: match.end));
  }

  return tokens;
}
