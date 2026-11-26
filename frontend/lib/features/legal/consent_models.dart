// Trách nhiệm file: Mô hình dữ liệu trạng thái đồng ý quyền riêng tư nhận từ backend.

class ConsentStatus {
  final String termsVersion;
  final String privacyVersion;
  final bool reconsentRequired;
  final DateTime? acceptedAt;

  const ConsentStatus({
    required this.termsVersion,
    required this.privacyVersion,
    required this.reconsentRequired,
    required this.acceptedAt,
  });

  factory ConsentStatus.fromJson(Map<String, dynamic> json) {
    final rawAcceptedAt = json['acceptedAt']?.toString();
    return ConsentStatus(
      termsVersion: json['termsVersion']?.toString() ?? '',
      privacyVersion: json['privacyVersion']?.toString() ?? '',
      reconsentRequired: json['reconsentRequired'] == true,
      acceptedAt: rawAcceptedAt != null && rawAcceptedAt.isNotEmpty
          ? DateTime.tryParse(rawAcceptedAt)
          : null,
    );
  }
}

