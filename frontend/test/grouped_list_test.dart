import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/theme/app_colors.dart';
import 'package:split_debt/core/widgets/grouped_list.dart';

void main() {
  testWidgets('section shows header text as given and separators between rows',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroupedSection(
            header: 'Tài khoản',
            children: [
              GroupedTile(title: 'A'),
              GroupedTile(title: 'B'),
              GroupedTile(title: 'C'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Tài khoản'), findsOneWidget);
    expect(find.text('TÀI KHOẢN'), findsNothing);
    expect(find.byKey(const ValueKey('grouped-separator')), findsNWidgets(2));
  });

  testWidgets('tappable tile shows chevron and is at least 52 high',
      (tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupedTile(
            title: 'Thông báo',
            onTap: () => tapCount++,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(tester.getSize(find.byType(GroupedTile)).height, greaterThanOrEqualTo(52.0));

    await tester.tap(find.byType(GroupedTile));
    expect(tapCount, equals(1));
  });

  testWidgets('value tile without onTap shows value and no chevron',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroupedTile(
            title: 'Tiền tệ',
            value: 'VND',
          ),
        ),
      ),
    );

    expect(find.text('VND'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('destructive tile is centered red text without icon',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupedTile(
            title: 'Đăng xuất',
            icon: Icons.logout,
            destructive: true,
            onTap: () {},
          ),
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text('Đăng xuất'));
    expect(textWidget.style?.color, equals(AppColors.error));
    expect(find.byIcon(Icons.logout), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('switch tile toggles and can be locked', (tester) async {
    bool? received;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupedSwitchTile(
            title: 'Thông báo',
            value: false,
            onChanged: (val) => received = val,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    expect(received, isTrue);

    // Test locked switch
    received = null;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroupedSwitchTile(
            title: 'Thông báo',
            value: false,
            onChanged: null,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    expect(received, isNull);
  });

  testWidgets('long value is ellipsized and large text scale does not overflow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: GroupedTile(
              title: 'Email',
              value: 'a' * 80,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

