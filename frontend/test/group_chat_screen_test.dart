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
  int afterCallCount = 0;
  List<ChatMessage> nextAfterMessages = [];
  bool shouldFailAfter = false;

  @override
  Future<MessagePage> latest(int groupId, {int limit = 30}) async {
    return MessagePage(messages: initialMessages, hasMore: false);
  }

  @override
  Future<List<ChatMessage>> after(int groupId, int afterId) async {
    afterCallCount++;
    if (shouldFailAfter) throw Exception('Network error');
    return nextAfterMessages;
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
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    mockRepo.initialMessages = [
      ChatMessage(
        id: 1,
        groupId: 10,
        senderId: 2,
        senderName: 'Bạn A',
        content: 'Chào cả nhóm!',
        clientMessageId: 'c1',
        createdAt: startOfToday.add(const Duration(minutes: 1)),
        status: ChatStatus.sent,
      ),
      ChatMessage(
        id: 2,
        groupId: 10,
        senderId: 1,
        senderName: 'Tôi',
        content: 'Chào bạn nhé!',
        clientMessageId: 'c2',
        createdAt: startOfToday.add(const Duration(minutes: 2)),
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

  testWidgets('adaptive polling: polls every 1s for 30s then slows to 5s when idle', (tester) async {
      final mockRepo = MockChatRepository();
      var fakeNow = DateTime(2026, 11, 27, 12, 0, 0);

      Future<void> advance(Duration d) async {
        const step = Duration(seconds: 1);
        var remaining = d;
        while (remaining >= step) {
          fakeNow = fakeNow.add(step);
          await tester.pump(step);
          remaining -= step;
        }
        if (remaining > Duration.zero) {
          fakeNow = fakeNow.add(remaining);
          await tester.pump(remaining);
        }
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(mockRepo),
            chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
          ],
          child: MaterialApp(
            home: GroupChatScreen(group: group, nowProvider: () => fakeNow),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await advance(const Duration(seconds: 30));
      final countAt30 = mockRepo.afterCallCount;
      expect(countAt30, greaterThanOrEqualTo(28));
      expect(countAt30, lessThanOrEqualTo(31));

      await advance(const Duration(seconds: 10));
      final deltaInSlow10s = mockRepo.afterCallCount - countAt30;
      expect(deltaInSlow10s, equals(2));
    });

    testWidgets('receiving a new message during slow poll switches back to 1s', (tester) async {
      final mockRepo = MockChatRepository();
      var fakeNow = DateTime(2026, 11, 27, 12, 0, 0);

      Future<void> advance(Duration d) async {
        const step = Duration(seconds: 1);
        var remaining = d;
        while (remaining >= step) {
          fakeNow = fakeNow.add(step);
          await tester.pump(step);
          remaining -= step;
        }
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(mockRepo),
            chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
          ],
          child: MaterialApp(
            home: GroupChatScreen(group: group, nowProvider: () => fakeNow),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Enter slow poll (>30s idle)
      await advance(const Duration(seconds: 35));
      mockRepo.nextAfterMessages = [
        ChatMessage(
          id: 500,
          groupId: 10,
          senderId: 2,
          senderName: 'B',
          content: 'Wake up!',
          clientMessageId: 'wake-500',
          createdAt: fakeNow,
          status: ChatStatus.sent,
        ),
      ];

      final beforeTrigger = mockRepo.afterCallCount;
      // Wait up to 5s for the slow poll tick to fire and fetch the new message
      await advance(const Duration(seconds: 5));
      expect(mockRepo.afterCallCount, greaterThan(beforeTrigger));

      // Clear new messages and verify next poll happens in 1s
      mockRepo.nextAfterMessages = [];
      final afterNewMsgCount = mockRepo.afterCallCount;
      await advance(const Duration(seconds: 1));
      expect(mockRepo.afterCallCount, equals(afterNewMsgCount + 1));
    });

    testWidgets('poll error backs off to 5s even when recently active', (tester) async {
      final mockRepo = MockChatRepository();
      var fakeNow = DateTime(2026, 11, 27, 12, 0, 0);
      mockRepo.shouldFailAfter = true;

      Future<void> advance(Duration d) async {
        const step = Duration(seconds: 1);
        var remaining = d;
        while (remaining >= step) {
          fakeNow = fakeNow.add(step);
          await tester.pump(step);
          remaining -= step;
        }
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(mockRepo),
            chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
          ],
          child: MaterialApp(
            home: GroupChatScreen(group: group, nowProvider: () => fakeNow),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // First fast poll fires at 1s and fails
      await advance(const Duration(seconds: 1));
      final countAfterFail = mockRepo.afterCallCount;
      expect(countAfterFail, equals(1));

      // Next 4s should NOT poll (backed off to 5s)
      await advance(const Duration(seconds: 4));
      expect(mockRepo.afterCallCount, equals(countAfterFail));

      // At 5s total since failure, it polls again
      await advance(const Duration(seconds: 1));
      expect(mockRepo.afterCallCount, equals(countAfterFail + 1));
    });

    testWidgets('disposing screen cancels timer and stops calling after', (tester) async {
      final mockRepo = MockChatRepository();
      var fakeNow = DateTime(2026, 11, 27, 12, 0, 0);
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(mockRepo),
            chatCurrentUserIdProvider.overrideWith((ref) => Future.value(1)),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            home: GroupChatScreen(group: group, nowProvider: () => fakeNow),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      navKey.currentState!.pushReplacement(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Other'))),
      );
      await tester.pumpAndSettle();

      final countAfterDispose = mockRepo.afterCallCount;
      fakeNow = fakeNow.add(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 10));
      expect(mockRepo.afterCallCount, equals(countAfterDispose));
    });
}
