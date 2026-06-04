import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../providers/chat_provider.dart';

class ChatRepository {
  final ChatProvider _provider = ChatProvider();

  Future<List<ConversationModel>> getConversations() async {
    final res = await _provider.getConversations();
    if (res['code'] == 0) {
      final data = res['data'];
      if (data == null || data is! List) return [];
      return data.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(res['message'] ?? '加载失败');
  }

  Future<ConversationModel> createConversation(String type, List<String> userIds, {String? name}) async {
    final res = await _provider.createConversation({
      'type': type,
      'userIds': userIds,
      if (name != null) 'name': name,
    });
    if (res['code'] == 0) {
      return ConversationModel.fromJson(res['data']);
    }
    throw Exception(res['message'] ?? '创建失败');
  }

  Future<List<MessageModel>> getMessages(String conversationId, {int page = 1}) async {
    final res = await _provider.getMessages(conversationId, page: page);
    if (res['code'] == 0) {
      final list = res['data'] as List;
      return list.map((e) => MessageModel.fromJson(e)).toList();
    }
    throw Exception(res['message'] ?? '加载失败');
  }

  Future<void> deleteConversation(String id) async {
    final res = await _provider.deleteConversation(id);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '删除失败');
    }
  }

  Future<ConversationModel> getConversation(String id) async {
    final res = await _provider.getConversation(id);
    if (res['code'] == 0) {
      return ConversationModel.fromJson(res['data']);
    }
    throw Exception(res['message'] ?? '加载失败');
  }

  Future<bool> pinConversation(String id) async {
    final res = await _provider.pinConversation(id);
    if (res['code'] == 0) {
      return res['data']['isPinned'] ?? false;
    }
    throw Exception(res['message'] ?? '操作失败');
  }

  Future<void> markUnread(String id) async {
    final res = await _provider.markUnread(id);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '操作失败');
    }
  }

  Future<void> markRead(String id) async {
    final res = await _provider.markRead(id);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '操作失败');
    }
  }
}
