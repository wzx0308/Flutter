import '../../core/network/api_client.dart';

class NotificationProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getNotifications({int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get('/notifications', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    final response = await _api.dio.get('/notifications/unread-count');
    return response.data;
  }

  Future<Map<String, dynamic>> markAllRead() async {
    final response = await _api.dio.patch('/notifications/read');
    return response.data;
  }

  Future<Map<String, dynamic>> markAsRead(String id) async {
    final response = await _api.dio.patch('/notifications/$id/read');
    return response.data;
  }
}
