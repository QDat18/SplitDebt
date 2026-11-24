import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/groups/widgets/empty_group_state.dart';
import 'package:split_debt/features/groups/widgets/error_state.dart';

void main() {
  group('EmptyGroupState & ErrorStateWidget overflow tests', () {
    testWidgets('EmptyGroupState renders without overflow on compact/landscape heights',
        (tester) async {
      // Giả lập màn hình landscape cực ngắn (ví dụ LDPlayer ở chế độ tablet 640x360 hoặc hẹp 320x400)
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyGroupState(
              onCreateGroup: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra không bị crash overflow
      expect(tester.takeException(), isNull);

      // Kiểm tra có đầy đủ text tiêu đề và nút
      expect(find.text('Chưa tham gia nhóm nào'), findsOneWidget);
      expect(find.text('Tạo nhóm ngay'), findsOneWidget);

      // Kiểm tra nhấn nút
      await tester.tap(find.text('Tạo nhóm ngay'));
      expect(tapped, isTrue);
    });

    testWidgets('ErrorStateWidget renders without overflow on compact/landscape heights',
        (tester) async {
      tester.view.physicalSize = const Size(640, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorMessage: 'Không thể kết nối máy chủ.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Có lỗi xảy ra'), findsOneWidget);
      expect(find.text('Không thể kết nối máy chủ.'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      expect(retried, isTrue);
    });
  });
}
