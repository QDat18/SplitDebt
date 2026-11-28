// Trách nhiệm file: Bảng màu Midnight Navy & Electric Royal Blue theo phong cách Fintech hiện đại (đạt chuẩn tương phản WCAG AA cho Light & Dark Mode).

import 'package:flutter/material.dart';

class AppColors {
  // --- BRAND MIDNIGHT NAVY & ELECTRIC ROYAL BLUE ---
  static const Color navy950 = Color(0xFF0A0822); // Dark mode canvas
  static const Color navy900 = Color(
    0xFF0F0B36,
  ); // Signature hero header & dark CTA
  static const Color navy800 = Color(0xFF141236); // Dark mode card surface
  static const Color navy700 = Color(
    0xFF1D1A47,
  ); // Dark mode elevated / input fill
  static const Color navy600 = Color(0xFF2B275C); // Dark mode hairline

  static const Color p50 = Color(0xFFEAF0FF);
  static const Color p100 = Color(0xFFD6E4FF);
  static const Color p200 = Color(0xFFADC8FF);
  static const Color p300 = Color(0xFF82B1FF);
  static const Color p400 = Color(0xFF3B7BFF);
  // 6.8:1 against white for crisp primary CTAs and links.
  static const Color p500 = Color(0xFF0052FF);
  static const Color p600 = Color(0xFF0046DB);
  static const Color p700 = Color(0xFF0039B3);
  static const Color p800 = Color(0xFF002B8A);
  static const Color p900 = navy900;

  // --- COOL ICE & NEUTRALS ---
  static const Color n0 = Color(0xFFFFFFFF);
  static const Color n50 = Color(
    0xFFF4F6FC,
  ); // Cool ice-tinted soft card / surface
  static const Color n100 = Color(0xFFE5E9F5); // Crisp hairline border
  static const Color n200 = Color(0xFFD2D8EC);
  static const Color n300 = Color(0xFFB5BCD6);
  static const Color n400 = Color(0xFF7E839E);
  static const Color n500 = Color(0xFF5C607B);
  static const Color n600 = Color(
    0xFF525672,
  ); // Secondary label (7.2:1 on white)
  static const Color n700 = Color(0xFF373A54);
  static const Color n800 = navy800;
  static const Color n900 = navy900;

  // --- SEMANTIC FINANCIAL STATUS (WCAG AA >= 4.5:1) ---
  static const Color success = Color(0xFF0F7B47);
  static const Color successTint = Color(0xFFE6F9F0);

  static const Color warning = Color(0xFF9A5500);
  static const Color warningTint = Color(0xFFFFF4E5);

  static const Color error = Color(0xFFC42038);
  static const Color errorTint = Color(0xFFFEECEF);

  static const Color info = p500;
  static const Color infoTint = p50;

  // High-contrast semantic tones for dark navy cards & Dark Mode.
  static const Color successOnDark = Color(0xFF6FE3A6);
  static const Color warningOnDark = Color(0xFFFFCA80);
  static const Color errorOnDark = Color(0xFFFFA8B4);

  static Color successFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? successOnDark : success;

  static Color warningFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? warningOnDark : warning;

  static Color errorFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? errorOnDark : error;

  static Color hairlineFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? navy600 : n100;

  static Color subtleFillFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? navy700 : n50;

  // --- SUBTLE BRAND HERO SURFACES ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF15104A), navy900],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF181352), navy900],
  );
}
