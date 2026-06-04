import '../../core/network/api_client.dart';

class BookmarkProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> toggleBookmark(String postId) async {
    final response = await _api.dio.post('/posts/$postId/bookmark');
    return response.data;
  }

  Future<Map<String, dynamic>> getMyBookmarks({int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get('/users/me/bookmarks', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> recordView(String postId) async {
    final response = await _api.dio.post('/posts/$postId/view');
    return response.data;
  }

  Future<Map<String, dynamic>> getMyHistory({int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get('/users/me/history', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> clearHistory() async {
    final response = await _api.dio.delete('/users/me/history');
    return response.data;
  }
}
