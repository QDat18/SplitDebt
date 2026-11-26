import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import 'chat_models.dart';

abstract class ChatRepository {
  Future<MessagePage> latest(int groupId);
  Future<MessagePage> before(int groupId, int id);
  Future<List<ChatMessage>> after(int groupId, int id);
  Future<ChatMessage> send(int groupId, String content, String clientMessageId);
  Future<void> markRead(int groupId, int lastId);
}

class DioChatRepository implements ChatRepository {
  final Dio _dio;

  DioChatRepository([Dio? dio]) : _dio = dio ?? dioClient;

  @override
  Future<MessagePage> latest(int groupId) async {
    final response = await _dio.get(
      '/groups/$groupId/messages',
      queryParameters: {'limit': 30},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final list = (data['messages'] as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    final hasMore = data['hasMore'] as bool? ?? false;
    return MessagePage(messages: list, hasMore: hasMore);
  }

  @override
  Future<MessagePage> before(int groupId, int id) async {
    final response = await _dio.get(
      '/groups/$groupId/messages',
      queryParameters: {'before': id, 'limit': 30},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final list = (data['messages'] as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    final hasMore = data['hasMore'] as bool? ?? false;
    return MessagePage(messages: list, hasMore: hasMore);
  }

  @override
  Future<List<ChatMessage>> after(int groupId, int id) async {
    final response = await _dio.get(
      '/groups/$groupId/messages',
      queryParameters: {'after': id},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final list = (data['messages'] as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  Future<ChatMessage> send(
      int groupId, String content, String clientMessageId) async {
    final response = await _dio.post(
      '/groups/$groupId/messages',
      data: {
        'content': content,
        'clientMessageId': clientMessageId,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ChatMessage.fromJson(data);
  }

  @override
  Future<void> markRead(int groupId, int lastId) async {
    await _dio.post(
      '/groups/$groupId/messages/read',
      data: {'lastReadMessageId': lastId},
    );
  }
}

