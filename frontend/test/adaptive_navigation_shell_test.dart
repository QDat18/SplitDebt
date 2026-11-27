import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/app/mobile_app_frame.dart';
import 'package:split_debt/core/theme/app_theme.dart';
import 'package:split_debt/core/widgets/adaptive_navigation_shell.dart';

const _labels = ['Trang chủ', 'Nhóm', 'Lịch sử', 'Cá nhân'];

void main() {
  testWidgets(
    'Phone tabs expose selection and the add button is at least 48dp',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        var selected = 0;
        var added = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: StatefulBuilder(
              builder: (context, setState) => AdaptiveNavigationShell(
                selectedIndex: selected,
                labels: _labels,
                addLabel: 'Thêm khoản chi',
                onSelect: (value) => setState(() => selected = value),
                onQuickAdd: () => added = true,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
        expect(find.byType(NavigationRail), findsNothing);
        expect(
          tester.getSemantics(find.bySemanticsLabel('Trang chủ')),
          containsSemantics(
            label: 'Trang chủ',
            isButton: true,
            isSelected: true,
            hasTapAction: true,
          ),
        );
        final add = find.byTooltip('Thêm khoản chi');
        expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(add).width, greaterThanOrEqualTo(48));
        await tester.tap(find.text('Nhóm'));
        await tester.pump();
        expect(selected, 1);
        await tester.tap(add);
        expect(added, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Resizing preserves entered text and uses the available desktop width',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (_, child) => MobileAppFrame(child: child!),
          home: AdaptiveNavigationShell(
            selectedIndex: 0,
            labels: _labels,
            addLabel: 'Thêm khoản chi',
            onSelect: (_) {},
            onQuickAdd: () {},
            child: const _DraftPage(),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Hóa đơn đang nhập');
      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );
      expect(find.text('Hóa đơn đang nhập'), findsOneWidget);
      tester.view.physicalSize = const Size(1800, 900);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );
      expect(find.text('viewport 1440'), findsOneWidget);
      expect(find.text('Hóa đơn đang nhập'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(900, 400),
    const Size(1300, 800),
  ]) {
    testWidgets('Navigation supports 200% text at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: AdaptiveNavigationShell(
            selectedIndex: 0,
            labels: _labels,
            addLabel: 'Thêm khoản chi',
            onSelect: (_) {},
            onQuickAdd: () {},
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

class _DraftPage extends StatelessWidget {
  const _DraftPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('viewport ${MediaQuery.sizeOf(context).width.toInt()}'),
        const TextField(),
      ],
    ),
  );
}
