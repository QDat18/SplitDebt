enum ChatStatus { sent, pending, failed, rejected }

class ChatMessage {
  final int? id;
  final int groupId;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final String clientMessageId;
  final ChatStatus status;
  final String? errorMessage;

  const ChatMessage({
    this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    required this.clientMessageId,
    this.status = ChatStatus.sent,
    this.errorMessage,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {ChatStatus status = ChatStatus.sent}) {
    return ChatMessage(
      id: json['id'] as int?,
      groupId: json['groupId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      clientMessageId: json['clientMessageId'] as String? ?? '',
      status: status,
    );
  }

  ChatMessage copyWith({
    int? id,
    int? groupId,
    int? senderId,
    String? senderName,
    String? content,
    DateTime? createdAt,
    String? clientMessageId,
    ChatStatus? status,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clientMessageId == other.clientMessageId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, clientMessageId, status);
}

class MessagePage {
  final List<ChatMessage> messages;
  final bool hasMore;

  const MessagePage({
    required this.messages,
    required this.hasMore,
  });
}

