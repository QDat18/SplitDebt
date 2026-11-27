import 'chat_models.dart';

sealed class ChatRow {
  const ChatRow();
}

class DayDividerRow extends ChatRow {
  final String label;
  const DayDividerRow(this.label);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayDividerRow &&
          runtimeType == other.runtimeType &&
          label == other.label;

  @override
  int get hashCode => label.hashCode;
}

class MessageRow extends ChatRow {
  final ChatMessage message;
  final bool isMine;
  final bool showSender;

  const MessageRow(
    this.message, {
    required this.isMine,
    required this.showSender,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageRow &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          isMine == other.isMine &&
          showSender == other.showSender;

  @override
  int get hashCode => Object.hash(message, isMine, showSender);
}

/// Merges current messages with incoming messages:
/// - Deduplicates by server `id`
/// - If a server message arrives with matching `clientMessageId`, it replaces any pending/failed message
/// - Server messages are sorted ascending by `id`
/// - Pending and failed messages always stay at the end, preserving insertion order
List<ChatMessage> mergeMessages(
    List<ChatMessage> current, List<ChatMessage> incoming) {
  final pendingAndFailed = <String, ChatMessage>{};

  for (final m in current) {
    if (m.status != ChatStatus.sent) {
      pendingAndFailed[m.clientMessageId] = m;
    }
  }

  for (final m in incoming) {
    if (m.status == ChatStatus.sent && m.id != null) {
      pendingAndFailed.remove(m.clientMessageId);
    } else if (m.status != ChatStatus.sent) {
      pendingAndFailed[m.clientMessageId] = m;
    }
  }

  final serverMessagesById = <int, ChatMessage>{};
  for (final m in current) {
    if (m.id != null) {
      serverMessagesById[m.id!] = m;
    }
  }
  for (final m in incoming) {
    if (m.id != null) {
      serverMessagesById[m.id!] = m;
    }
  }

  final sortedServer = serverMessagesById.values.toList()
    ..sort((a, b) => a.id!.compareTo(b.id!));

  return [...sortedServer, ...pendingAndFailed.values];
}

String _formatDayLabel(DateTime date, DateTime now) {
  final localDate = date.toLocal();
  final localNow = now.toLocal();
  final d = DateTime(localDate.year, localDate.month, localDate.day);
  final n = DateTime(localNow.year, localNow.month, localNow.day);

  final diffDays = n.difference(d).inDays;
  if (diffDays == 0) {
    return 'Hôm nay';
  } else if (diffDays == 1) {
    return 'Hôm qua';
  } else {
    final dd = localDate.day.toString().padLeft(2, '0');
    final mm = localDate.month.toString().padLeft(2, '0');
    final yyyy = localDate.year.toString();
    return '$dd/$mm/$yyyy';
  }
}

/// Transforms a list of sorted messages into displayable [ChatRow]s:
/// - Inserts [DayDividerRow] ("Hôm nay", "Hôm qua", dd/MM/yyyy) when the date changes
/// - Calculates `showSender`: true when !isMine and (is first message, different sender,
///   gap >= 5 minutes, or crossed a day boundary).
List<ChatRow> buildChatRows(
    List<ChatMessage> messages, DateTime now, int myUserId) {
  final rows = <ChatRow>[];
  DateTime? lastDay;
  ChatMessage? prevMsg;

  for (final msg in messages) {
    final localMsgTime = msg.createdAt.toLocal();
    final currentDay =
        DateTime(localMsgTime.year, localMsgTime.month, localMsgTime.day);

    bool crossedDay = false;
    if (lastDay == null || currentDay != lastDay) {
      crossedDay = true;
      lastDay = currentDay;
      rows.add(DayDividerRow(_formatDayLabel(msg.createdAt, now)));
    }

    final isMine = msg.senderId == myUserId;
    bool showSender = false;
    if (!isMine) {
      if (crossedDay || prevMsg == null || prevMsg.senderId != msg.senderId) {
        showSender = true;
      } else {
        final diff = msg.createdAt.difference(prevMsg.createdAt).abs();
        if (diff.inMinutes >= 5) {
          showSender = true;
        }
      }
    }

    rows.add(MessageRow(msg, isMine: isMine, showSender: showSender));
    prevMsg = msg;
  }

  return rows;
}

