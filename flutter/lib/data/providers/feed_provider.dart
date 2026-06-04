import '../../core/network/api_client.dart';

class FeedProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getFeed({int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get('/posts', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }
}
