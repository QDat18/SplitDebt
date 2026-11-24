import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/utils/invite_code_parser.dart';

void main() {
  group('InviteCodeParser tests', () {
    test('extracts code from standard https url', () {
      expect(
        InviteCodeParser.parse('https://splitdebt.app/join/GR-9A8B2C'),
        'GR-9A8B2C',
      );
    });

    test('extracts code from url with trailing slash', () {
      expect(
        InviteCodeParser.parse('https://splitdebt.app/join/GR-9A8B2C/'),
        'GR-9A8B2C',
      );
    });

    test('extracts code from url with query params', () {
      expect(
        InviteCodeParser.parse('https://splitdebt.app/join/GR-9A8B2C?ref=zalo&src=share'),
        'GR-9A8B2C',
      );
    });

    test('extracts code from deep link schema', () {
      expect(
        InviteCodeParser.parse('splitdebt://join/GR-9A8B2C'),
        'GR-9A8B2C',
      );
    });

    test('extracts code when user pastes raw invite code', () {
      expect(
        InviteCodeParser.parse('GR-9A8B2C'),
        'GR-9A8B2C',
      );
    });

    test('handles whitespace and empty strings', () {
      expect(InviteCodeParser.parse('   '), '');
      expect(InviteCodeParser.parse(null), '');
      expect(
        InviteCodeParser.parse('  https://splitdebt.app/join/CODE123  '),
        'CODE123',
      );
    });

    test('builds correct invite url', () {
      expect(
        InviteCodeParser.buildInviteUrl('GR-9A8B2C'),
        'https://splitdebt.app/join/GR-9A8B2C',
      );
    });
  });
}

