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
  r'(?<![0-9A-Za-z.,])([0-9OoIlSB]{1,3}(?:[.,][0-9OoIlSB]{3})+|[0-9OoIlSB]{1,3}(?: [0-9OoIlSB]{3})+|[0-9OoIlSB]{1,6}[kK]|[0-9OoIlSB]{4,9}|[0-9]{1,3}[.,][0-9]{1,2})(?:\s*(?:đ|d|vnd|vnđ))?(?![0-9A-Za-z.,])',
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
final RegExp _phoneLikeRegex = RegExp(
  r'(?<![0-9A-Za-z.,])(?:\+84[\s.-]?[1-9](?:[\s.-]?\d){7,8}|0[1-9](?:[\s.-]?\d){7,9}|(?:1800|1900)[\s.-]?\d{4,6})(?![0-9A-Za-z.,])',
);

List<MoneyToken> parseMoneyTokens(String row) {
  final tokens = <MoneyToken>[];
  var sanitizedRow = row.replaceAllMapped(
    _dateLikeRegex,
    (m) => ' ' * (m.end - m.start),
  );
  sanitizedRow = sanitizedRow.replaceAllMapped(
    _phoneLikeRegex,
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
    final parsed = int.tryParse(digitsOnly);
    if (parsed == null) continue;

    final value = isK ? parsed * 1000 : parsed;
    if (value < 1000 || value > 100000000) continue;

    tokens.add(MoneyToken(value: value, start: match.start, end: match.end));
  }

  return tokens;
}
