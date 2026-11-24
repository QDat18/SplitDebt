import 'dart:async';
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
}
