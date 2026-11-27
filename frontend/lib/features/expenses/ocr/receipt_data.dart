import 'dart:convert';

class ReceiptLine {
  final String name;
  final int quantity, unitPrice;
  int get amount => quantity * unitPrice;
  const ReceiptLine(this.name, this.quantity, this.unitPrice);
}

class ReceiptDraft {
  final int total;
  final List<ReceiptLine> items;
  final DateTime date;
  final String merchant, source;
  const ReceiptDraft(
    this.total,
    this.items,
    this.date,
    this.merchant,
    this.source,
  );
  int get subtotal => items.fold(0, (sum, item) => sum + item.amount);
}

const _maxMoney = 999999999999;

String? _receiptDate(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final date = DateTime.tryParse(value);
  if (date == null ||
      date.year < 2000 ||
      date.year > DateTime.now().year + 1 ||
      date.toIso8601String().substring(0, 10) != value) {
    return null;
  }
  return value;
}

Map<String, String> _tlv(String raw) {
  final tags = <String, String>{};
  var offset = 0;
  while (offset + 4 <= raw.length) {
    final id = raw.substring(offset, offset + 2);
    final lengthText = raw.substring(offset + 2, offset + 4);
    final length = int.tryParse(lengthText);
    if (!RegExp(r'^\d{2}$').hasMatch(id) ||
        !RegExp(r'^\d{2}$').hasMatch(lengthText) ||
        length == null ||
        offset + 4 + length > raw.length ||
        tags.containsKey(id)) {
      throw const FormatException(
        'Mã QR bị thiếu hoặc sai dữ liệu. Hãy quét lại.',
      );
    }
    tags[id] = raw.substring(offset + 4, offset + 4 + length);
    offset += 4 + length;
  }
  if (offset != raw.length) {
    throw const FormatException('Mã QR chưa đầy đủ. Hãy quét lại.');
  }
  return tags;
}

// QR carries untrusted data. Never follow URLs or treat payment data as an invoice.
Map<String, dynamic> parseReceiptQr(String raw) {
  raw = raw.trim().replaceFirst(RegExp(r'^\uFEFF'), '').trim();
  if (raw.isEmpty || raw.length > 24000) {
    throw const FormatException('Nội dung QR trống hoặc quá dài.');
  }
  if (raw.startsWith('{')) {
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['type'] != 'splitdebt_receipt' ||
        data['currency'] != 'VND' ||
        (data['version'] != null && data['version'] != 1)) {
      throw const FormatException(
        'QR này không phải hóa đơn SplitDebt bằng VND được hỗ trợ.',
      );
    }
    final items = data['items'];
    if (items is! List || items.length > 100) {
      throw const FormatException('Danh sách hàng trong QR không hợp lệ.');
    }
    bool positive(Object? x, int limit) => x is int && x > 0 && x <= limit;
    if (!positive(data['total'], _maxMoney)) {
      throw const FormatException('Tổng tiền trong QR không hợp lệ.');
    }
    if (data['merchant'] != null &&
        (data['merchant'] is! String ||
            (data['merchant'] as String).length > 160)) {
      throw const FormatException('Tên cửa hàng trong QR không hợp lệ.');
    }
    final rows = <Map<String, dynamic>>[];
    for (final item in items) {
      if (item is! Map ||
          item['name'] is! String ||
          (item['name'] as String).trim().isEmpty ||
          (item['name'] as String).length > 160 ||
          !positive(item['quantity'], 999) ||
          !positive(item['unitPrice'], _maxMoney)) {
        throw const FormatException('Dòng hàng trong QR không hợp lệ.');
      }
      final amount = (item['quantity'] as int) * (item['unitPrice'] as int);
      if (amount > _maxMoney ||
          (item['amount'] != null && item['amount'] != amount)) {
        throw const FormatException(
          'Thành tiền trong QR không khớp số lượng và đơn giá.',
        );
      }
      rows.add({
        'name': (item['name'] as String).trim(),
        'quantity': item['quantity'],
        'unitPrice': item['unitPrice'],
        'amount': amount,
      });
    }
    final date = _receiptDate(data['date']);
    final subtotal = rows.fold<int>(
      0,
      (sum, row) => sum + (row['amount'] as int),
    );
    return {
      'total': data['total'],
      'date': date,
      'merchant': data['merchant'],
      'items': rows,
      'warnings': <String>[
        if (date == null)
          'QR không có ngày hợp lệ. Hãy chọn ngày trên hóa đơn.',
        if (rows.isNotEmpty && subtotal != data['total'])
          'Tổng dòng hàng khác tổng thanh toán. Kiểm tra thuế, giảm giá hoặc phụ phí trên hóa đơn.',
      ],
    };
  }
  if (raw.startsWith('000201') && raw.codeUnits.every((x) => x < 128)) {
    final tags = _tlv(raw);
    if (tags['00'] != '01' ||
        tags['53'] != '704' ||
        tags['58'] != 'VN' ||
        !RegExp(r'6304[0-9A-Fa-f]{4}$').hasMatch(raw) ||
        tags['63']?.length != 4 ||
        tags.keys.last != '63') {
      throw const FormatException('Không nhận dạng được VietQR bằng VND.');
    }
    final account = _tlv(tags['38'] ?? '');
    if (account['00'] != 'A000000727' ||
        !['QRIBFTTA', 'QRIBFTTC'].contains(account['02']) ||
        (account['01'] ?? '').isEmpty) {
      throw const FormatException('Thông tin VietQR không hợp lệ.');
    }
    final bank = _tlv(account['01']!);
    if ((bank['00'] ?? '').isEmpty || (bank['01'] ?? '').isEmpty) {
      throw const FormatException('Thông tin tài khoản VietQR không đầy đủ.');
    }
    var crc = 0xffff;
    for (final b in raw.substring(0, raw.length - 4).codeUnits) {
      crc ^= b << 8;
      for (var j = 0; j < 8; j++) {
        crc = ((crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1) & 0xffff;
      }
    }
    if (crc != int.tryParse(tags['63']!, radix: 16)) {
      throw const FormatException(
        'QR bị lỗi kiểm tra. Hãy quét lại mã rõ hơn.',
      );
    }
    int? amount;
    if (tags.containsKey('54')) {
      final value = tags['54']!;
      amount = RegExp(r'^\d{1,12}(?:\.0{1,2})?$').hasMatch(value)
          ? int.tryParse(value.split('.').first)
          : null;
      if (amount == null || amount <= 0 || amount > _maxMoney) {
        throw const FormatException('Số tiền VietQR không hợp lệ.');
      }
    }
    return {
      'total': amount,
      'date': null,
      'merchant': tags['59'],
      'items': <Map<String, dynamic>>[],
      'warnings': <String>[
        'Đây là mã thanh toán VietQR, không phải hóa đơn và không xác nhận đã trả tiền. Hãy đối chiếu số tiền và bổ sung ngày chi từ hóa đơn.',
      ],
    };
  }
  throw const FormatException(
    'QR này không chứa chi tiết hóa đơn được hỗ trợ. Với QR tra cứu hóa đơn, hãy tải ảnh hóa đơn từ nhà cung cấp rồi chọn Quét ảnh.',
  );
}
