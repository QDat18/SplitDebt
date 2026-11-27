import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/constants/app_constants.dart';

void main() {
  test('pubspec.yaml version matches AppConstants.appVersion', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([^\s+#]+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'version line not found in pubspec.yaml');

    final pubspecVersion = match!.group(1)!.split('+').first;
    expect(pubspecVersion, equals(AppConstants.appVersion));
  });
}
