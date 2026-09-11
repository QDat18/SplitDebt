import 'package:flutter/material.dart';

/// BẢNG MÀU XÉN NỢ DESIGN SYSTEM v1.0.0 (Design Tokens)
class AppColors {
  // --- PRIMARY BRAND (TÍM XÉN NỢ) ---
  static const Color p50 = Color(0xFFF1EFFE);
  static const Color p100 = Color(0xFFE3E0FD);
  static const Color p200 = Color(0xFFC9C2FC);
  static const Color p300 = Color(0xFFA397FA);
  static const Color p400 = Color(0xFF806CF7);
  static const Color p500 = Color(0xFF6C5CE7); // Primary Brand Color
  static const Color p600 = Color(0xFF5A4BD2);
  static const Color p700 = Color(0xFF493BB8);
  static const Color p800 = Color(0xFF4433B0);
  static const Color p900 = Color(0xFF241B60);

  // --- NEUTRALS (TRUNG TÍNH) ---
  static const Color n0 = Color(0xFFFFFFFF); // White
  static const Color n50 = Color(0xFFF8F9FC);
  static const Color n100 = Color(0xFFF3F4F8);
  static const Color n200 = Color(0xFFEBEAED);
  static const Color n300 = Color(0xFFD2D0D6);
  static const Color n400 = Color(0xFFB8B5C0);
  static const Color n500 = Color(0xFF9E9AA9);
  static const Color n600 = Color(0xFF687280);
  static const Color n700 = Color(0xFF4B5563);
  static const Color n800 = Color(0xFF1E1E24);
  static const Color n900 = Color(0xFF14151A);

  // --- SEMANTICS & TINTS (TRẠNG THÁI TÀI CHÍNH) ---
  static const Color success = Color(0xFF22C55E);
  static const Color successTint = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningTint = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFEF4444);
  static const Color errorTint = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoTint = Color(0xFFDBEAFE);

  // --- GRADIENTS (DẢI MÀU) ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [p900, p500, p700],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [p500, p700],
  );
}
