import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/network/dio_client.dart';
import 'package:split_debt/core/theme/app_theme.dart';
import 'package:split_debt/data/repositories/auth_repository.dart';
import 'package:split_debt/features/expenses/create_expense_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Interceptor> originalInterceptors;
  late int saveRequests;

  setUp(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:8081/api');
    AuthRepository.setCachedUserId(1);
    saveRequests = 0;
    originalInterceptors = List.of(dioClient.interceptors);
    dioClient.interceptors.clear();
    dioClient.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          final Object data;
          switch (request.path) {
            case '/groups':
              data = [
                {'id': 1, 'name': 'Nhóm bạn'},
              ];
            case '/groups/1/members':
              data = [
                {'userId': 1, 'fullName': 'Nguyễn An'},
                {'userId': 2, 'fullName': 'Trần Bình'},
              ];
            case '/v1/categories':
              data = <Object>[];
            case '/v1/expenses':
              saveRequests++;
              data = <String, Object>{};
            default:
              data = <Object>[];
          }
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {'data': data},
            ),
          );
        },
      ),
    );
  });

  tearDown(() {
    dioClient.interceptors
      ..clear()
      ..addAll(originalInterceptors);
    AuthRepository.clearCache();
  });

  Future<void> showForm(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const CreateExpenseScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );
  }

  testWidgets('form fits narrow, wide and enlarged-text devices', (
    tester,
  ) async {
    for (final scenario in [
      (const Size(320, 780), 1.0),
      (const Size(1280, 900), 1.0),
      (const Size(390, 844), 1.6),
    ]) {
      await showForm(tester, scenario.$1, textScale: scenario.$2);
      expect(find.text('Thông tin khoản chi'), findsOneWidget);
      expect(find.text('Lưu khoản chi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('switching to scan and back preserves typed expense details', (
    tester,
  ) async {
    await showForm(tester, const Size(390, 844));
    final title = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Tên khoản chi',
    );
    final amount = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Tổng số tiền',
    );
    await tester.enterText(title, 'Bữa trưa');
    await tester.enterText(amount, '175000');
    await tester.ensureVisible(find.text('Quét hóa đơn'));
    await tester.tap(find.text('Quét hóa đơn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhập thủ công'));
    await tester.pumpAndSettle();
    expect(find.text('Bữa trưa'), findsOneWidget);
    expect(find.text('175000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty form cannot submit an expense', (tester) async {
    await showForm(tester, const Size(390, 844));
    await tester.tap(find.text('Lưu khoản chi'));
    await tester.pumpAndSettle();
    expect(saveRequests, 0);
    expect(find.text('Nhập tên để dễ tìm lại khoản chi.'), findsOneWidget);
    expect(find.text('Nhập số tiền lớn hơn 0 đồng.'), findsOneWidget);
  });

  testWidgets('all split methods fit a narrow device with large text', (
    tester,
  ) async {
    await showForm(tester, const Size(320, 780), textScale: 1.6);
    for (final label in ['Số tiền', '%', 'Hệ số', 'Theo món', 'Chia đều']) {
      final tab = find.widgetWithText(ChoiceChip, label);
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      expect(tester.takeException(), isNull, reason: 'Split method: $label');
    }
  });

  testWidgets('amount shares keep visible integer VND and an exact total', (
    tester,
  ) async {
    await showForm(tester, const Size(390, 844));
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Tổng số tiền',
      ),
      '100001',
    );
    final mode = find.widgetWithText(ChoiceChip, 'Số tiền');
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    final shares = tester
        .widgetList<TextField>(find.byType(TextField))
        .where(
          (field) =>
              field.decoration?.labelText?.startsWith('Phần của ') ?? false,
        )
        .map((field) => int.parse(field.controller!.text))
        .toList();
    expect(shares, [50001, 50000]);
    expect(shares.reduce((a, b) => a + b), 100001);
  });

  testWidgets('percent balancing preserves two decimal places', (tester) async {
    await showForm(tester, const Size(390, 844));
    final mode = find.widgetWithText(ChoiceChip, '%');
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    final share = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Phần của Nguyễn An',
    );
    await tester.ensureVisible(share);
    await tester.enterText(share, '50.25');
    await tester.pumpAndSettle();
    expect(find.text('49.75'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing an item name preserves quantity and unit price', (
    tester,
  ) async {
    await showForm(tester, const Size(390, 844));
    final mode = find.widgetWithText(ChoiceChip, 'Theo món');
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Thêm món'));
    await tester.tap(find.text('Thêm món'));
    await tester.pumpAndSettle();
    Finder input(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
    await tester.enterText(input('Tên món'), 'Cơm gà');
    await tester.enterText(input('Số lượng'), '2');
    await tester.enterText(input('Đơn giá'), '45000');
    await tester.tap(find.text('Lưu món'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sửa món'));
    await tester.tap(find.text('Sửa món'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input('Số lượng')).controller!.text, '2');
    expect(
      tester.widget<TextField>(input('Đơn giá')).controller!.text,
      '45000',
    );
    await tester.enterText(input('Tên món'), 'Cơm gà xối mỡ');
    await tester.tap(find.text('Lưu món'));
    await tester.pumpAndSettle();
    expect(find.text('Cơm gà xối mỡ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
