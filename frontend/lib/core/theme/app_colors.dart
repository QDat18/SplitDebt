// Trách nhiệm file: Định nghĩa bảng màu chuẩn iOS Human Interface Guidelines (Light & Dark) cho toàn ứng dụng.

import 'package:flutter/material.dart';

class AppColors {
  // --- PRIMARY iOS SYSTEM BLUE ---
  static const Color p50 = Color(0xFFEAF3FF);
  static const Color p100 = Color(0xFFD6E8FF);
  static const Color p200 = Color(0xFFAED1FF);
  static const Color p300 = Color(0xFF7CB4FF);
  static const Color p400 = Color(0xFF3A94FF);
  // 5.4:1 against white so button labels and normal-size links stay readable.
  static const Color p500 = Color(0xFF0066D6);
  static const Color p600 = Color(0xFF0066D6);
  static const Color p700 = Color(0xFF0051AD);
  static const Color p800 = Color(0xFF003E85);
  static const Color p900 = Color(0xFF1C1C1E); // iOS Matte Charcoal

  // --- iOS SYSTEM NEUTRALS ---
  static const Color n0 = Color(0xFFFFFFFF);
  static const Color n50 = Color(0xFFF2F2F7); // iOS systemGroupedBackground
  static const Color n100 = Color(0xFFE5E5EA); // iOS systemGray5
  static const Color n200 = Color(0xFFD1D1D6); // iOS systemGray4
  static const Color n300 = Color(0xFFC7C7CC); // iOS systemGray3
  static const Color n400 = Color(0xFF73737B);
  static const Color n500 = Color(0xFF686870);
  static const Color n600 = Color(0xFF636366); // iOS secondaryLabel
  static const Color n700 = Color(0xFF48484A);
  static const Color n800 = Color(
    0xFF2C2C2E,
  ); // iOS secondarySystemGroupedBackground (dark)
  static const Color n900 = Color(0xFF1C1C1E); // iOS label / dark card

  // --- iOS SEMANTICS ---
  static const Color success = Color(0xFF16713B);
  static const Color successTint = Color(0xFFE8F8ED);

  static const Color warning = Color(0xFF935200);
  static const Color warningTint = Color(0xFFFFF4E5);

  static const Color error = Color(0xFFBF2922);
  static const Color errorTint = Color(0xFFFFECEB);

  static const Color info = p500;
  static const Color infoTint = Color(0xFFEAF3FF);

  static Color successFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF79D69A)
      : success;

  static Color warningFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFFCA80)
      : warning;

  static Color errorFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFFB4AB)
      : error;

  // --- SUBTLE iOS SURFACES (No loud AI gradients) ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
  );
}
