// Trách nhiệm file: Màn hình nhắn tin nhóm (GroupChatScreen) chuẩn Apple HIG / iOS Design.

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../groups/models/group_model.dart';
import 'active_chat.dart';
import 'chat_logic.dart';
import 'chat_models.dart';
import 'chat_notifier.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupChatScreen({super.key, required this.group});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen>
    with WidgetsBindingObserver {
  late final int _groupId;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _pollTimer;
  Timer? _markReadDebounce;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  int? _lastMarkedReadId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _groupId = int.tryParse(widget.group.id) ?? 0;
    ActiveChat.groupId = _groupId;

    _scrollController.addListener(_onScroll);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatNotifierProvider(_groupId).notifier).loadInitial();
        _startPolling();
        _listenToFcm();
      }
    });
  }

  void _listenToFcm() {
    try {
      _fcmSubscription =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (!mounted) return;
        final type = message.data['type']?.toString();
        final gId = message.data['groupId']?.toString();
        if (type == 'GROUP_MESSAGE' && gId == '$_groupId') {
          ref.read(chatNotifierProvider(_groupId).notifier).refreshNewer();
        }
      });
    } catch (_) {
      // Firebase messaging might not be initialized in test or desktop environment
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (ref.read(chatNotifierProvider(_groupId)).removed) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.read(chatNotifierProvider(_groupId).notifier).refreshNewer();
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ActiveChat.groupId = _groupId;
      _startPolling();
      ref.read(chatNotifierProvider(_groupId).notifier).refreshNewer();
    } else {
      _stopPolling();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatNotifierProvider(_groupId).notifier).loadOlder();
    }
  }

  void _scheduleMarkRead(int newestId) {
    if (_lastMarkedReadId != null && newestId <= _lastMarkedReadId!) return;
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        _lastMarkedReadId = newestId;
        ref.read(chatNotifierProvider(_groupId).notifier).markRead(newestId);
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {});

    final notifier = ref.read(chatNotifierProvider(_groupId).notifier);
    await notifier.send(text);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (ActiveChat.groupId == _groupId) {
      ActiveChat.groupId = null;
    }
    _stopPolling();
    _markReadDebounce?.cancel();
    _fcmSubscription?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(chatNotifierProvider(_groupId), (_, next) {
      if (next.removed) {
        _stopPolling();
      }
    });
    final chatState = ref.watch(chatNotifierProvider(_groupId));
    final currentUserIdAsync = ref.watch(chatCurrentUserIdProvider);
    final currentUserId = currentUserIdAsync.valueOrNull ?? 0;

    // Trigger mark read if new server messages arrived
    if (chatState.newestServerId != null) {
      _scheduleMarkRead(chatState.newestServerId!);
    }

    final rows = buildChatRows(chatState.messages, DateTime.now(), currentUserId);
    final displayRows = rows.reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS System Gray 6
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.n900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.group.memberCount} ${context.tr('thành viên', 'members')}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.n500,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chatState.loadingInitial
                  ? const Center(
                      child: CircularProgressIndicator.adaptive(),
                    )
                  : displayRows.isEmpty
                      ? Center(
                          child: Text(
                            context.tr(
                              'Chưa có tin nhắn nào.\nHãy gửi lời chào đến cả nhóm!',
                              'No messages yet.\nSay hello to the group!',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.n500,
                              height: 1.4,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: displayRows.length +
                              (chatState.loadingOlder ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (chatState.loadingOlder &&
                                index == displayRows.length) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final row = displayRows[index];
                            if (row is DayDividerRow) {
                              return _buildDayDivider(row.label);
                            } else if (row is MessageRow) {
                              return _buildMessageBubble(
                                context,
                                row.message,
                                row.isMine,
                                row.showSender,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
            ),
            chatState.removed
                ? _buildRemovedBanner(context)
                : _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        context.tr(
          'Bạn không còn là thành viên của nhóm này.',
          'You are no longer a member of this group.',
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.n500,
        ),
      ),
    );
  }

  Widget _buildDayDivider(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.n600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage message,
    bool isMine,
    bool showSender,
  ) {
    final timeStr =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    final bubbleColumn = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine && showSender)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.n600,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isMine ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 16 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 16),
                  ),
                  boxShadow: isMine
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: isMine ? Colors.white : AppColors.n900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isMine ? Colors.white70 : AppColors.n400,
                          ),
                        ),
                        if (isMine && message.status == ChatStatus.pending) ...[
                          const SizedBox(width: 4),
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('Đang gửi', 'Sending'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isMine && message.status == ChatStatus.failed)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: GestureDetector(
                onTap: () {
                  ref
                      .read(chatNotifierProvider(_groupId).notifier)
                      .retry(message.clientMessageId);
                },
                child: Text(
                  context.tr(
                    'Chưa gửi được · Chạm để thử lại',
                    'Failed to send · Tap to retry',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (isMine && message.status == ChatStatus.rejected)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Text(
                message.errorMessage ??
                    context.tr('Tin nhắn không hợp lệ', 'Invalid message'),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );

    if (isMine && message.status == ChatStatus.rejected) {
      return Dismissible(
        key: ValueKey('msg-${message.clientMessageId}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          ref
              .read(chatNotifierProvider(_groupId).notifier)
              .removeLocalMessage(message.clientMessageId);
        },
        child: GestureDetector(
          onLongPress: () {
            ref
                .read(chatNotifierProvider(_groupId).notifier)
                .removeLocalMessage(message.clientMessageId);
          },
          child: bubbleColumn,
        ),
      );
    }

    return bubbleColumn;
  }

  Widget _buildInputBar() {
    final canSend = _textController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9EB), // iOS search / input gray
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) {
                  if (maxLength == null) return null;
                  final remaining = maxLength - currentLength;
                  if (remaining >= 200) return null;
                  return Text(
                    '$currentLength/$maxLength',
                    style: TextStyle(
                      fontSize: 11,
                      color: remaining <= 20 ? AppColors.error : AppColors.n500,
                    ),
                  );
                },
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.tr('Nhập tin nhắn...', 'Type a message...'),
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    color: AppColors.n500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canSend ? AppColors.primary : AppColors.n200,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.send_rounded,
                size: 18,
                color: canSend ? Colors.white : AppColors.n400,
              ),
              onPressed: canSend ? _handleSend : null,
            ),
          ),
        ],
      ),
    );
  }
}
