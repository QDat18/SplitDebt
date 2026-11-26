import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/chat/active_chat.dart';
import 'package:split_debt/features/chat/chat_models.dart';
import 'package:split_debt/features/chat/chat_notifier.dart';
import 'package:split_debt/features/chat/chat_repository.dart';
import 'package:split_debt/features/chat/group_chat_screen.dart';
import 'package:split_debt/features/groups/models/group_model.dart';

class MockChatRepository implements ChatRepository {
  List<ChatMessage> initialMessages = [];
  Completer<ChatMessage>? sendCompleter;
  DioException? sendDioException;
  int? markedReadId;
  String? lastSentContent;
  String? lastSentClientMessageId;

  @override
  Future<MessagePage> latest(int groupId, {int limit = 30}) async {
    return MessagePage(messages: initialMessages, hasMore: false);
  }

  @override
  Future<List<ChatMessage>> after(int groupId, int afterId) async {
    return [];
  }

  @override
  Future<MessagePage> before(int groupId, int beforeId, {int limit = 30}) async {
    return MessagePage(messages: [], hasMore: false);
  }

  @override
  Future<ChatMessage> send(int groupId, String content, String clientMessageId) async {
    lastSentContent = content;
    lastSentClientMessageId = clientMessageId;
    if (sendDioException != null) throw sendDioException!;
    if (sendCompleter != null) {
      return sendCompleter!.future;
    }
    return ChatMessage(
      id: 99,
      groupId: groupId,
      senderId: 1,
      senderName: 'Tôi',
      content: content,
      clientMessageId: clientMessageId,
      createdAt: DateTime.now(),
      status: ChatStatus.sent,
    );
  }

  @override
  Future<void> markRead(int groupId, int lastMessageId) async {
    markedReadId = lastMessageId;
  }
}

void main() {
  final group = GroupModel(
    id: '10',
    name: 'Nhóm Đi Chơi',
    currentUserRole: 'MEMBER',
    memberCount: 3,
  );

  testWidgets('sets and clears ActiveChat.groupId lifecycle', (tester) async {
    final mockRepo = MockChatRepository();
    expect(ActiveChat.groupId, isNull);

    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
        ],
        child: MaterialApp(
          navigatorKey: navKey,
          home: GroupChatScreen(group: group),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(ActiveChat.groupId, 10);

    // Navigate to another screen to unmount GroupChatScreen
    navKey.currentState!.pushReplacement(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Home')),
      ),
    );
    await tester.pumpAndSettle();

    expect(ActiveChat.groupId, isNull);
  });

  testWidgets('renders messages and day divider correctly', (tester) async {
    final mockRepo = MockChatRepository();
    final today = DateTime.now();
    mockRepo.initialMessages = [
      ChatMessage(
        id: 1,
        groupId: 10,
        senderId: 2,
        senderName: 'Bạn A',
        content: 'Chào cả nhóm!',
        clientMessageId: 'c1',
        createdAt: today.subtract(const Duration(minutes: 10)),
        status: ChatStatus.sent,
      ),
      ChatMessage(
        id: 2,
        groupId: 10,
        senderId: 1,
        senderName: 'Tôi',
        content: 'Chào bạn nhé!',
        clientMessageId: 'c2',
        createdAt: today.subtract(const Duration(minutes: 5)),
        status: ChatStatus.sent,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
        ],
        child: MaterialApp(
          home: GroupChatScreen(group: group),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhóm Đi Chơi'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Chào cả nhóm!'), findsOneWidget);
    expect(find.text('Bạn A'), findsOneWidget);
    expect(find.text('Chào bạn nhé!'), findsOneWidget);
  });

  testWidgets('typing text enables send button and sends message', (tester) async {
    final mockRepo = MockChatRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
        ],
        child: MaterialApp(
          home: GroupChatScreen(group: group),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inputFinder = find.byType(TextField);
    expect(inputFinder, findsOneWidget);

    // Enter message
    await tester.enterText(inputFinder, 'Tin nhắn thử nghiệm');
    await tester.pump();

    final sendButton = find.byIcon(Icons.send_rounded);
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(mockRepo.lastSentContent, 'Tin nhắn thử nghiệm');
    expect(find.text('Tin nhắn thử nghiệm'), findsOneWidget);
  });

  testWidgets('failed message shows retry and tapping triggers retry', (tester) async {
    final mockRepo = MockChatRepository();
    mockRepo.initialMessages = [
      ChatMessage(
        id: null,
        groupId: 10,
        senderId: 1,
        senderName: 'Tôi',
        content: 'Tin bị lỗi',
        clientMessageId: 'c-failed',
        createdAt: DateTime.now(),
        status: ChatStatus.failed,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
        ],
        child: MaterialApp(
          home: GroupChatScreen(group: group),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retryFinder = find.text('Chưa gửi được · Chạm để thử lại');
    expect(retryFinder, findsOneWidget);

    await tester.tap(retryFinder);
    await tester.pumpAndSettle();

    expect(mockRepo.lastSentClientMessageId, 'c-failed');
    expect(mockRepo.lastSentContent, 'Tin bị lỗi');
  });

  testWidgets('input enforces maxLength 2000 and shows counter only when < 200 remaining', (tester) async {
    final mockRepo = MockChatRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
        ],
        child: MaterialApp(
          home: GroupChatScreen(group: group),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.maxLength, equals(2000));

    // At 100 chars (1900 remaining >= 200), counter should be hidden
    await tester.enterText(find.byType(TextField), 'a' * 100);
    await tester.pump();
    expect(find.text('100/2000'), findsNothing);

    // At 1850 chars (150 remaining < 200), counter should be shown
    await tester.enterText(find.byType(TextField), 'a' * 1850);
    await tester.pump();
    expect(find.text('1850/2000'), findsOneWidget);
  });

  testWidgets('rejected message shows server error without retry and long press removes it', (tester) async {
    final mockRepo = MockChatRepository();
    mockRepo.initialMessages = [
      ChatMessage(
        id: null,
        groupId: 10,
        senderId: 1,
        senderName: 'Tôi',
        content: 'Tin bị từ chối',
        clientMessageId: 'c-rejected',
        createdAt: DateTime.now(),
        status: ChatStatus.rejected,
        errorMessage: 'Tin nhắn không hợp lệ',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
        ],
        child: MaterialApp(
          home: GroupChatScreen(group: group),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tin nhắn không hợp lệ'), findsOneWidget);
    expect(find.text('Chưa gửi được · Chạm để thử lại'), findsNothing);

    await tester.longPress(find.text('Tin bị từ chối'));
    await tester.pumpAndSettle();

    expect(find.text('Tin bị từ chối'), findsNothing);
  });

  testWidgets('HTTP 403 on send hides input bar and shows removed message', (tester) async {
    final mockRepo = MockChatRepository();
    mockRepo.sendDioException = DioException(
      requestOptions: RequestOptions(path: '/groups/10/messages'),
      response: Response(
        requestOptions: RequestOptions(path: '/groups/10/messages'),
        statusCode: 403,
      ),
      type: DioExceptionType.badResponse,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
        ],
        child: MaterialApp(
          home: GroupChatScreen(group: group),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Bạn không còn là thành viên của nhóm này.'), findsOneWidget);
  });
}
