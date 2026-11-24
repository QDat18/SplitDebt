import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/history/history_screen.dart';

void main() {
  testWidgets('history screen renders iOS AppBar and Cupertino segmented control',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HistoryScreen(history: true),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify AppBar title for History mode
    expect(find.text('Lịch sử'), findsOneWidget);

    // Verify Cupertino Sliding Segmented Control exists
    expect(find.byType(CupertinoSlidingSegmentedControl<int>), findsOneWidget);

    // Verify segment options
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Chi tiêu'), findsOneWidget);
    expect(find.text('Thanh toán'), findsOneWidget);
    expect(find.text('Nhận tiền'), findsOneWidget);
  });

  testWidgets('stats screen renders iOS AppBar title and stats segmented control',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HistoryScreen(history: false),
      ),
    );

    await tester.pump();

    expect(find.text('Thống kê'), findsOneWidget);
    expect(find.byType(CupertinoSlidingSegmentedControl<int>), findsOneWidget);
    expect(find.text('Tuần'), findsOneWidget);
    expect(find.text('Tháng'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
  });
}

