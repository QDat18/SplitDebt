import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/chat/chat_logic.dart';
import 'package:split_debt/features/chat/chat_models.dart';
import 'package:split_debt/features/chat/uuid.dart';

void main() {
  group('uuidV4', () {
    test('uuidV4 matches RFC 4122 v4 format', () {
      final pattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      for (int i = 0; i < 50; i++) {
        final id = uuidV4();
        expect(pattern.hasMatch(id), isTrue, reason: '$id is not RFC 4122 v4');
      }
    });
  });

  group('mergeMessages', () {
    test('merge dedupes by id and sorts ascending', () {
      final current = [
        ChatMessage(
          id: 3,
          groupId: 1,
          senderId: 1,
          senderName: 'A',
          content: 'Msg 3',
          createdAt: DateTime(2026, 11, 25, 10, 3),
          clientMessageId: 'c3',
        ),
        ChatMessage(
          id: 1,
          groupId: 1,
          senderId: 1,
          senderName: 'A',
          content: 'Msg 1',
          createdAt: DateTime(2026, 11, 25, 10, 1),
          clientMessageId: 'c1',
        ),
      ];
      final incoming = [
        ChatMessage(
          id: 2,
          groupId: 1,
          senderId: 2,
          senderName: 'B',
          content: 'Msg 2',
          createdAt: DateTime(2026, 11, 25, 10, 2),
          clientMessageId: 'c2',
        ),
        ChatMessage(
          id: 1,
          groupId: 1,
          senderId: 1,
          senderName: 'A',
          content: 'Msg 1 duplicate',
          createdAt: DateTime(2026, 11, 25, 10, 1),
          clientMessageId: 'c1',
        ),
      ];

      final merged = mergeMessages(current, incoming);
      expect(merged.map((m) => m.id), equals([1, 2, 3]));
      expect(merged[0].content, equals('Msg 1 duplicate'));
    });

    test('merge replaces pending by clientMessageId and keeps pending last', () {
      final pending1 = ChatMessage(
        id: null,
        groupId: 1,
        senderId: 1,
        senderName: 'A',
        content: 'Pending 1',
        createdAt: DateTime(2026, 11, 25, 10, 5),
        clientMessageId: 'p1',
        status: ChatStatus.pending,
      );
      final pending2 = ChatMessage(
        id: null,
        groupId: 1,
        senderId: 1,
        senderName: 'A',
        content: 'Pending 2',
        createdAt: DateTime(2026, 11, 25, 10, 6),
        clientMessageId: 'p2',
        status: ChatStatus.pending,
      );
      final server1 = ChatMessage(
        id: 10,
        groupId: 1,
        senderId: 1,
        senderName: 'A',
        content: 'Pending 1 confirmed',
        createdAt: DateTime(2026, 11, 25, 10, 5),
        clientMessageId: 'p1',
        status: ChatStatus.sent,
      );

      final merged = mergeMessages([pending1, pending2], [server1]);
      expect(merged.length, equals(2));
      expect(merged[0].id, equals(10));
      expect(merged[0].status, equals(ChatStatus.sent));
      expect(merged[1].clientMessageId, equals('p2'));
      expect(merged[1].status, equals(ChatStatus.pending));
    });
  });

  group('buildChatRows', () {
    test('rows insert day dividers with Hôm nay / Hôm qua / dd/MM/yyyy', () {
      final now = DateTime(2026, 11, 25, 12, 0);
      final messages = [
        ChatMessage(
          id: 1,
          groupId: 1,
          senderId: 2,
          senderName: 'B',
          content: 'Old msg',
          createdAt: DateTime(2026, 11, 20, 8, 0),
          clientMessageId: 'm1',
        ),
        ChatMessage(
          id: 2,
          groupId: 1,
          senderId: 2,
          senderName: 'B',
          content: 'Yesterday msg',
          createdAt: DateTime(2026, 11, 24, 15, 0),
          clientMessageId: 'm2',
        ),
        ChatMessage(
          id: 3,
          groupId: 1,
          senderId: 1,
          senderName: 'Me',
          content: 'Today msg',
          createdAt: DateTime(2026, 11, 25, 9, 0),
          clientMessageId: 'm3',
        ),
      ];

      final rows = buildChatRows(messages, now, 1);
      expect(rows.length, equals(6)); // 3 dividers + 3 messages
      expect(rows[0], isA<DayDividerRow>());
      expect((rows[0] as DayDividerRow).label, equals('20/11/2026'));
      expect(rows[1], isA<MessageRow>());
      expect(rows[2], isA<DayDividerRow>());
      expect((rows[2] as DayDividerRow).label, equals('Hôm qua'));
      expect(rows[3], isA<MessageRow>());
      expect(rows[4], isA<DayDividerRow>());
      expect((rows[4] as DayDividerRow).label, equals('Hôm nay'));
      expect(rows[5], isA<MessageRow>());
    });

    test('rows show sender only at start of a 5-minute run from same person', () {
      final now = DateTime(2026, 11, 25, 12, 0);
      final messages = [
        // B sends 3 messages within 5 mins
        ChatMessage(
          id: 1,
          groupId: 1,
          senderId: 2,
          senderName: 'B',
          content: 'Msg 1',
          createdAt: DateTime(2026, 11, 25, 10, 0),
          clientMessageId: 'm1',
        ),
        ChatMessage(
          id: 2,
          groupId: 1,
          senderId: 2,
          senderName: 'B',
          content: 'Msg 2',
          createdAt: DateTime(2026, 11, 25, 10, 2),
          clientMessageId: 'm2',
        ),
        // B sends another msg 6 minutes later
        ChatMessage(
          id: 3,
          groupId: 1,
          senderId: 2,
          senderName: 'B',
          content: 'Msg 3',
          createdAt: DateTime(2026, 11, 25, 10, 8),
          clientMessageId: 'm3',
        ),
        // My message (should never show sender)
        ChatMessage(
          id: 4,
          groupId: 1,
          senderId: 1,
          senderName: 'Me',
          content: 'My reply',
          createdAt: DateTime(2026, 11, 25, 10, 9),
          clientMessageId: 'm4',
        ),
      ];

      final rows = buildChatRows(messages, now, 1);
      final msgRows = rows.whereType<MessageRow>().toList();

      expect(msgRows[0].showSender, isTrue); // Start of run
      expect(msgRows[1].showSender, isFalse); // Within 2 mins of prev msg from B
      expect(msgRows[2].showSender, isTrue); // 6 mins later -> new run
      expect(msgRows[3].isMine, isTrue);
      expect(msgRows[3].showSender, isFalse); // My message
    });
  });
}
