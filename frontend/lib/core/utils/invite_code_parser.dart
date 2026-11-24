// Trách nhiệm file: Trích xuất nhanh mã nhóm từ URL, mã QR hoặc chuỗi nhập tay của người dùng.

class InviteCodeParser {
  /// Trích xuất mã nhóm (invite code) từ chuỗi URL, mã QR hoặc mã nhập tay.
  /// Ví dụ:
  /// - "https://splitdebt.app/join/GR-9A8B2C" -> "GR-9A8B2C"
  /// - "https://splitdebt.com/groups/join/GR-9A8B2C/" -> "GR-9A8B2C"
  /// - "splitdebt://join/GR-9A8B2C?ref=share" -> "GR-9A8B2C"
  /// - "GR-9A8B2C" -> "GR-9A8B2C"
  static String parse(String? input) {
    if (input == null) return '';
    var raw = input.trim();
    if (raw.isEmpty) return '';

    // 1. Cắt bỏ query parameters nếu có (ví dụ ?ref=..., ?src=...)
    if (raw.contains('?')) {
      raw = raw.split('?').first;
    }

    // 2. Cắt bỏ hash/fragment nếu có (#/join/...)
    if (raw.contains('#')) {
      raw = raw.split('#').last;
    }

    // 3. Loại bỏ các dấu gạch chéo dư thừa ở cuối URL
    while (raw.endsWith('/')) {
      raw = raw.substring(0, raw.length - 1);
    }

    // 4. Lấy phần tử cuối cùng sau dấu '/' (mã nhóm)
    final segments = raw.split('/');
    final code = segments.isNotEmpty ? segments.last.trim() : raw;

    return code;
  }

  /// Tạo đường dẫn mời chuẩn cho nhóm
  static String buildInviteUrl(String inviteCode) {
    return 'https://splitdebt.app/join/$inviteCode';
  }
}

