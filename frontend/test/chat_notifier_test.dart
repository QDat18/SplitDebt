import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/chat/chat_models.dart';
import 'package:split_debt/features/chat/chat_notifier.dart';
import 'package:split_debt/features/chat/chat_repository.dart';

class FakeChatRepository implements ChatRepository {
  List<ChatMessage> mockLatest = [];
  bool mockLatestHasMore = false;
  List<ChatMessage> mockBefore = [];
  bool mockBeforeHasMore = false;
  List<ChatMessage> mockAfter = [];
  bool shouldFailSend = false;
  bool shouldFailAfter = false;
  bool shouldFailLatest = false;
  int latestCallCount = 0;
  int afterCallCount = 0;

  final List<String> sentIds = [];

  @override
  Future<MessagePage> latest(int groupId) async {
    latestCallCount++;
    if (shouldFailLatest) throw Exception('Initial load error');
    return MessagePage(messages: mockLatest, hasMore: mockLatestHasMore);
  }

  @override
  Future<MessagePage> before(int groupId, int id) async {
    return MessagePage(messages: mockBefore, hasMore: mockBeforeHasMore);
  }

  @override
  Future<List<ChatMessage>> after(int groupId, int id) async {
    afterCallCount++;
    if (shouldFailAfter) throw Exception('Network error');
    return mockAfter;
  }

  @override
  Future<ChatMessage> send(int groupId, String content, String clientMessageId) async {
    sentIds.add(clientMessageId);
    if (shouldFailSend) throw Exception('Send failed');
    return ChatMessage(
      id: 999,
      groupId: groupId,
      senderId: 1,
      senderName: 'Me',
      content: content,
      createdAt: DateTime.now(),
      clientMessageId: clientMessageId,
      status: ChatStatus.sent,
    );
  }

  @override
  Future<void> markRead(int groupId, int lastId) async {}
}

void main() {
  group('ChatNotifier', () {
    late FakeChatRepository repo;
    late ChatNotifier notifier;

    setUp(() {
      repo = FakeChatRepository();
      notifier = ChatNotifier(
        repository: repo,
        groupId: 10,
        myUserId: 1,
        myUserName: 'Me',
      );
    });

    test('send success replaces pending with server message', () async {
      await notifier.send('Hello server');

      expect(notifier.state.messages.length, equals(1));
      expect(notifier.state.messages.first.status, equals(ChatStatus.sent));
      expect(notifier.state.messages.first.id, equals(999));
    });

    test('send failure marks failed; retry reuses the same clientMessageId', () async {
      repo.shouldFailSend = true;
      await notifier.send('Failed msg');

      expect(notifier.state.messages.length, equals(1));
      expect(notifier.state.messages.first.status, equals(ChatStatus.failed));
      final failedClientMsgId = notifier.state.messages.first.clientMessageId;

      repo.shouldFailSend = false;
      await notifier.retry(failedClientMsgId);

      expect(notifier.state.messages.length, equals(1));
      expect(notifier.state.messages.first.status, equals(ChatStatus.sent));
      expect(repo.sentIds, equals([failedClientMsgId, failedClientMsgId]));
    });

    test('refreshNewer returning the same message as pending does not duplicate', () async {
      // User sent pending message
      repo.shouldFailSend = true;
      await notifier.send('Msg in flight');
      final clientMsgId = notifier.state.messages.first.clientMessageId;

      // Poll returns the confirmed server message
      repo.mockAfter = [
        ChatMessage(
          id: 50,
          groupId: 10,
          senderId: 1,
          senderName: 'Me',
          content: 'Msg in flight',
          createdAt: DateTime.now(),
          clientMessageId: clientMsgId,
          status: ChatStatus.sent,
        ),
      ];

      await notifier.refreshNewer();

      expect(notifier.state.messages.length, equals(1));
      expect(notifier.state.messages.first.id, equals(50));
      expect(notifier.state.messages.first.status, equals(ChatStatus.sent));
    });

    test('refreshNewer error keeps messages and sets no error', () async {
      repo.mockLatest = [
        ChatMessage(
          id: 1,
          groupId: 10,
          senderId: 2,
          senderName: 'B',
          content: 'Existing msg',
          createdAt: DateTime.now(),
          clientMessageId: 'c1',
          status: ChatStatus.sent,
        ),
      ];
      await notifier.loadInitial();

      repo.shouldFailAfter = true;
      await notifier.refreshNewer();

      expect(notifier.state.messages.length, equals(1));
      expect(notifier.state.error, isNull);
    });

    test('loadOlder prepends and updates hasMore', () async {
      repo.mockLatest = [
        ChatMessage(
          id: 10,
          groupId: 10,
          senderId: 2,
          senderName: 'B',
          content: 'Latest msg',
          createdAt: DateTime.now(),
          clientMessageId: 'c10',
          status: ChatStatus.sent,
        ),
      ];
      repo.mockLatestHasMore = true;
      await notifier.loadInitial();

      repo.mockBefore = [
        ChatMessage(
          id: 5,
          groupId: 10,
          senderId: 2,
          senderName: 'B',
          content: 'Older msg',
          createdAt: DateTime.now(),
          clientMessageId: 'c5',
          status: ChatStatus.sent,
        ),
      ];
      repo.mockBeforeHasMore = false;

      await notifier.loadOlder();

      expect(notifier.state.messages.length, equals(2));
      expect(notifier.state.messages[0].id, equals(5));
      expect(notifier.state.messages[1].id, equals(10));
      expect(notifier.state.hasMore, isFalse);
    });

    test('refreshNewer calls loadInitial when newestServerId is null and state has error', () async {
      repo.shouldFailLatest = true;
      await notifier.loadInitial();
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.newestServerId, isNull);
      expect(repo.latestCallCount, equals(1));

      repo.shouldFailLatest = false;
      repo.mockLatest = [
        ChatMessage(
          id: 7,
          groupId: 10,
          senderId: 2,
          senderName: 'B',
          content: 'Recovered',
          createdAt: DateTime.now(),
          clientMessageId: 'c7',
          status: ChatStatus.sent,
        ),
      ];

      await notifier.refreshNewer();

      expect(repo.latestCallCount, equals(2));
      expect(repo.afterCallCount, equals(0));
      expect(notifier.state.error, isNull);
      expect(notifier.state.messages.length, equals(1));
      expect(notifier.state.messages.first.id, equals(7));
    });

    test('refreshNewer calls after(0) when newestServerId is null and state has no error', () async {
      repo.mockLatest = [];
      await notifier.loadInitial();
      expect(notifier.state.error, isNull);
      expect(notifier.state.newestServerId, isNull);

      await notifier.refreshNewer();

      expect(repo.latestCallCount, equals(1));
      expect(repo.afterCallCount, equals(1));
    });
  });
}
