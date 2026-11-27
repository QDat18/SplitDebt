// Trách nhiệm file: Quản lý trạng thái 3 ô đồng ý bắt buộc trên màn hình đăng ký.

class RegisterConsentState {
  final bool terms;
  final bool privacy;
  final bool age;

  const RegisterConsentState({
    this.terms = false,
    this.privacy = false,
    this.age = false,
  });

  bool get canSubmit => terms && privacy && age;

  RegisterConsentState copyWith({
    bool? terms,
    bool? privacy,
    bool? age,
  }) {
    return RegisterConsentState(
      terms: terms ?? this.terms,
      privacy: privacy ?? this.privacy,
      age: age ?? this.age,
    );
  }
}

