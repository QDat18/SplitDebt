import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import 'chat_logic.dart';
import 'chat_models.dart';
import 'chat_repository.dart';
import 'uuid.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool loadingInitial;
  final bool loadingOlder;
  final bool hasMore;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.loadingInitial = false,
    this.loadingOlder = false,
    this.hasMore = false,
    this.error,
  });

  int? get newestServerId {
    int? maxId;
    for (final m in messages) {
      if (m.id != null) {
        if (maxId == null || m.id! > maxId) {
          maxId = m.id;
        }
      }
    }
    return maxId;
  }

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loadingInitial,
    bool? loadingOlder,
    bool? hasMore,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      loadingInitial: loadingInitial ?? this.loadingInitial,
      loadingOlder: loadingOlder ?? this.loadingOlder,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final int groupId;
  int myUserId;
  String myUserName;
  bool _isRefreshingNewer = false;

  ChatNotifier({
    required ChatRepository repository,
    required this.groupId,
    required this.myUserId,
    this.myUserName = '',
  })  : _repository = repository,
        super(const ChatState());

  void updateCurrentUser(int id, [String name = '']) {
    myUserId = id;
    if (name.isNotEmpty) myUserName = name;
  }

  Future<void> loadInitial() async {
    state = state.copyWith(loadingInitial: true, error: null);
    try {
      final page = await _repository.latest(groupId);
      if (mounted) {
        state = state.copyWith(
          messages: page.messages,
          hasMore: page.hasMore,
          loadingInitial: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          loadingInitial: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> loadOlder() async {
    if (state.loadingOlder || !state.hasMore || state.messages.isEmpty) return;
    int? firstServerId;
    for (final m in state.messages) {
      if (m.id != null) {
        if (firstServerId == null || m.id! < firstServerId) {
          firstServerId = m.id;
        }
      }
    }
    if (firstServerId == null) return;

    state = state.copyWith(loadingOlder: true);
    try {
      final page = await _repository.before(groupId, firstServerId);
      if (mounted) {
        state = state.copyWith(
          messages: mergeMessages(page.messages, state.messages),
          hasMore: page.hasMore,
          loadingOlder: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loadingOlder: false);
      }
    }
  }

  Future<void> refreshNewer() async {
    if (state.loadingInitial || _isRefreshingNewer) return;
    final lastId = state.newestServerId ?? 0;

    _isRefreshingNewer = true;
    try {
      final newMsgs = await _repository.after(groupId, lastId);
      if (mounted) {
        state = state.copyWith(
          messages: mergeMessages(state.messages, newMsgs),
        );
      }
    } catch (_) {
      // Silent on poll error
    } finally {
      _isRefreshingNewer = false;
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final clientMsgId = uuidV4();
    final pending = ChatMessage(
      id: null,
      groupId: groupId,
      senderId: myUserId,
      senderName: myUserName,
      content: trimmed,
      createdAt: DateTime.now(),
      clientMessageId: clientMsgId,
      status: ChatStatus.pending,
    );

    state = state.copyWith(messages: [...state.messages, pending]);

    try {
      final serverMsg = await _repository.send(groupId, trimmed, clientMsgId);
      if (mounted) {
        state = state.copyWith(
          messages: mergeMessages(state.messages, [serverMsg]),
        );
      }
    } catch (e) {
      if (mounted) {
        final updated = state.messages.map((m) {
          if (m.clientMessageId == clientMsgId) {
            return m.copyWith(status: ChatStatus.failed);
          }
          return m;
        }).toList();
        state = state.copyWith(messages: updated);
      }
    }
  }

  Future<void> retry(String clientMessageId) async {
    ChatMessage? target;
    for (final m in state.messages) {
      if (m.clientMessageId == clientMessageId) {
        target = m;
        break;
      }
    }
    if (target == null || target.status != ChatStatus.failed) return;

    final updated = state.messages.map((m) {
      if (m.clientMessageId == clientMessageId) {
        return m.copyWith(status: ChatStatus.pending);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);

    try {
      final serverMsg =
          await _repository.send(groupId, target.content, clientMessageId);
      if (mounted) {
        state = state.copyWith(
          messages: mergeMessages(state.messages, [serverMsg]),
        );
      }
    } catch (e) {
      if (mounted) {
        final failedAgain = state.messages.map((m) {
          if (m.clientMessageId == clientMessageId) {
            return m.copyWith(status: ChatStatus.failed);
          }
          return m;
        }).toList();
        state = state.copyWith(messages: failedAgain);
      }
    }
  }

  Future<void> markRead(int lastId) async {
    try {
      await _repository.markRead(groupId, lastId);
    } catch (_) {
      // Ignored
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return DioChatRepository();
});

final chatCurrentUserIdProvider = FutureProvider<int>((ref) async {
  return AuthRepository().getCurrentUserId();
});

final chatNotifierProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, ChatState, int>((ref, groupId) {
  final repo = ref.watch(chatRepositoryProvider);
  final userIdAsync = ref.watch(chatCurrentUserIdProvider);
  final myUserId = userIdAsync.valueOrNull ?? 0;
  return ChatNotifier(
    repository: repo,
    groupId: groupId,
    myUserId: myUserId,
  );
});
