import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/groups/models/group_model.dart';
import 'package:split_debt/features/groups/screens/group_settings_screen.dart';

void main() {
  final adminGroup = GroupModel(
    id: '1',
    name: 'Nhóm Du Lịch',
    description: 'Chuyến đi Hà Giang',
    currentUserRole: 'ADMIN',
    memberCount: 4,
  );

  final memberGroup = GroupModel(
    id: '2',
    name: 'Nhóm Bạn Thân',
    description: 'Ăn uống cuối tuần',
    currentUserRole: 'MEMBER',
    memberCount: 3,
  );

  testWidgets('admin sees text inputs, Save button, and delete tile',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GroupSettingsScreen(group: adminGroup),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check AppBar Save button
    expect(find.text('Cài đặt nhóm'), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);

    // Check section and form fields
    expect(find.text('Thông tin nhóm'), findsOneWidget);
    expect(find.text('Tên'), findsOneWidget);
    expect(find.text('Mô tả'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Check delete tile
    final deleteFinder = find.text('Xoá nhóm');
    expect(deleteFinder, findsOneWidget);

    // Tap delete opens dialog
    await tester.tap(deleteFinder);
    await tester.pumpAndSettle();

    expect(find.text('Xoá nhóm này?'), findsOneWidget);
    expect(
      find.text(
        'Toàn bộ khoản chi và lịch sử của nhóm sẽ bị xoá. Không thể hoàn tác.',
      ),
      findsOneWidget,
    );
    expect(find.text('Huỷ'), findsOneWidget);
    expect(find.text('Xoá'), findsOneWidget);

    // Tap Huỷ closes dialog
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();

    expect(find.text('Xoá nhóm này?'), findsNothing);
  });

  testWidgets('member sees read-only values, no Save button, no delete tile',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GroupSettingsScreen(group: memberGroup),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Member should NOT see Save button
    expect(find.text('Lưu'), findsNothing);

    // Member should see read-only values
    expect(find.text('Nhóm Bạn Thân'), findsOneWidget);
    expect(find.text('Ăn uống cuối tuần'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    // Member should see footer
    expect(
      find.text('Chỉ trưởng nhóm hoặc quản trị viên mới sửa được.'),
      findsOneWidget,
    );

    // Member should NOT see delete tile
    expect(find.text('Xoá nhóm'), findsNothing);
  });

  testWidgets('save disabled when name has trailing spaces but unchanged',
      (tester) async {
    final groupWithSpaces = GroupModel(
      id: '3',
      name: 'Du lịch ',
      description: 'Mô tả nhóm ',
      currentUserRole: 'ADMIN',
      memberCount: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GroupSettingsScreen(group: groupWithSpaces),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveButton =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Lưu'));
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('member sees full multi-line description', (tester) async {
    const multiLineDesc =
        'Câu thứ nhất của mô tả nhóm.\nCâu thứ hai giải thích thêm chi tiết.\nCâu thứ ba chốt lại mục tiêu của nhóm.';
    final groupWithMultiLine = GroupModel(
      id: '4',
      name: 'Nhóm Leo Núi',
      description: multiLineDesc,
      currentUserRole: 'MEMBER',
      memberCount: 5,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GroupSettingsScreen(group: groupWithMultiLine),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Câu thứ ba chốt lại'), findsOneWidget);
  });
}
