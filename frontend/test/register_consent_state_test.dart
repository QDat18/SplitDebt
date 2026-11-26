import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/auth/register_consent_state.dart';

void main() {
  test('initial state has nothing pre-checked', () {
    const state = RegisterConsentState();
    expect(state.terms, isFalse);
    expect(state.privacy, isFalse);
    expect(state.age, isFalse);
    expect(state.canSubmit, isFalse);
  });

  test('cannot submit until all three boxes are checked', () {
    const initial = RegisterConsentState();
    expect(initial.canSubmit, isFalse);

    final twoChecked = initial.copyWith(terms: true, privacy: true);
    expect(twoChecked.canSubmit, isFalse);

    final allChecked = twoChecked.copyWith(age: true);
    expect(allChecked.canSubmit, isTrue);
  });
}

