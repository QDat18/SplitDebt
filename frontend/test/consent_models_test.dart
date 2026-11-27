import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/legal/consent_models.dart';

void main() {
  test('ConsentStatus parses reconsentRequired and acceptedAt', () {
    final withNullDate = ConsentStatus.fromJson({
      'termsVersion': '2026-11-26',
      'privacyVersion': '2026-11-26',
      'reconsentRequired': true,
      'acceptedAt': null,
    });
    expect(withNullDate.termsVersion, '2026-11-26');
    expect(withNullDate.privacyVersion, '2026-11-26');
    expect(withNullDate.reconsentRequired, isTrue);
    expect(withNullDate.acceptedAt, isNull);

    final withIsoDate = ConsentStatus.fromJson({
      'termsVersion': '2026-11-26',
      'privacyVersion': '2026-11-26',
      'reconsentRequired': false,
      'acceptedAt': '2026-11-26T10:00:00',
    });
    expect(withIsoDate.reconsentRequired, isFalse);
    expect(withIsoDate.acceptedAt, DateTime.parse('2026-11-26T10:00:00'));
  });
}

