import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/theme/app_colors.dart';
import 'package:split_debt/core/theme/app_theme.dart';

double _contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
}

void main() {
  test('Normal semantic labels meet WCAG AA against their tint and white', () {
    for (final pair in [
      (AppColors.success, AppColors.successTint),
      (AppColors.warning, AppColors.warningTint),
      (AppColors.error, AppColors.errorTint),
      (AppColors.info, AppColors.infoTint),
    ]) {
      expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      expect(_contrast(pair.$1, Colors.white), greaterThanOrEqualTo(4.5));
    }
  });

  for (final mode in ['light', 'dark']) {
    test('$mode text, controls and input states have readable contrast', () {
      final theme = mode == 'light' ? AppTheme.lightTheme : AppTheme.darkTheme;
      final scheme = theme.colorScheme;
      final input = theme.inputDecorationTheme;
      expect(
        _contrast(scheme.primary, scheme.onPrimary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.primary, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.onSurfaceVariant, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(input.hintStyle!.color!, input.fillColor!),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(input.errorStyle!.color!, input.fillColor!),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(input.enabledBorder!.borderSide.color, input.fillColor!),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(input.focusedBorder!.borderSide.color, input.fillColor!),
        greaterThanOrEqualTo(3),
      );
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      expect(
        theme.iconButtonTheme.style!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(48),
      );
      expect(
        theme.textButtonTheme.style!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(48),
      );
    });
  }

  testWidgets('Semantic label helpers keep contrast on dark cards', (
    tester,
  ) async {
    late BuildContext cardContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) {
            cardContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final surface = Theme.of(cardContext).colorScheme.surface;
    for (final color in [
      AppColors.successFor(cardContext),
      AppColors.warningFor(cardContext),
      AppColors.errorFor(cardContext),
    ]) {
      expect(_contrast(color, surface), greaterThanOrEqualTo(4.5));
    }
  });
}
