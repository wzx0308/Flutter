import '../../core/network/api_client.dart';

class ChatProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getConversations() async {
    final response = await _api.dio.get('/conversations');
    return response.data;
  }

  Future<Map<String, dynamic>> getConversation(String id) async {
    final response = await _api.dio.get('/conversations/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createConversation(Map<String, dynamic> data) async {
    final response = await _api.dio.post('/conversations', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getMessages(String conversationId, {int page = 1, int pageSize = 50}) async {
    final response = await _api.dio.get('/conversations/$conversationId/messages', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> deleteConversation(String id) async {
    final response = await _api.dio.delete('/conversations/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> pinConversation(String id) async {
    final response = await _api.dio.patch('/conversations/$id/pin');
    return response.data;
  }

  Future<Map<String, dynamic>> markUnread(String id) async {
    final response = await _api.dio.patch('/conversations/$id/unread');
    return response.data;
  }

  Future<Map<String, dynamic>> markRead(String id) async {
    final response = await _api.dio.patch('/conversations/$id/read');
    return response.data;
  }
}
