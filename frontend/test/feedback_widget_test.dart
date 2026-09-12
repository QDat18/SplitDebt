import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/theme/app_theme.dart';
import 'package:split_debt/widgets/design.dart';

void main() {
  testWidgets('success error warning and info feedback render distinct messages', (tester) async {
    late BuildContext inner;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Builder(builder: (context) {
          inner = context;
          return const SizedBox();
        }),
      ),
    ));

    showSuccess(inner, 'Đã lưu khoản chi', title: 'Thành công');
    await tester.pump();
    expect(find.text('Thành công'), findsOneWidget);
    expect(find.text('Đã lưu khoản chi'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    showWarning(inner, 'Tổng phần trăm chưa bằng 100%');
    await tester.pump();
    expect(find.text('Cần kiểm tra'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    showInfo(inner, 'Settlement đang chờ xác nhận');
    await tester.pump();
    expect(find.text('Thông tin'), findsOneWidget);
    expect(find.byIcon(Icons.info_rounded), findsOneWidget);

    showError(inner, 'timeout while connecting');
    await tester.pump();
    expect(find.text('Có lỗi xảy ra'), findsOneWidget);
    expect(find.textContaining('Kết nối quá thời gian'), findsOneWidget);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
  });

  testWidgets('success dialog has clear result and action', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(builder: (context) => Scaffold(
        body: FilledButton(
          onPressed: () => showSuccessDialog(
            context,
            title: 'Thanh toán thành công',
            message: 'Khoản công nợ đã được xác nhận.',
            actionLabel: 'Xong',
          ),
          child: const Text('Open'),
        ),
      )),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán thành công'), findsOneWidget);
    expect(find.text('Khoản công nợ đã được xác nhận.'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán thành công'), findsNothing);
  });
}
