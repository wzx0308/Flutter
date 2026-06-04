import '../../core/network/api_client.dart';

class SearchProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> search(String query, {String? type, int page = 1}) async {
    final response = await _api.dio.get('/search', queryParameters: {
      'q': query,
      if (type != null) 'type': type,
      'page': page,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getTrending() async {
    final response = await _api.dio.get('/search/trending');
    return response.data;
  }

  Future<Map<String, dynamic>> getRecommended({int page = 1}) async {
    final response = await _api.dio.get('/discover/recommended', queryParameters: {'page': page});
    return response.data;
  }

  Future<Map<String, dynamic>> getNearby(double lat, double lng, {double radius = 10, int page = 1}) async {
    final response = await _api.dio.get('/discover/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'page': page,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getTagPosts(String tag, {int page = 1}) async {
    final response = await _api.dio.get('/tags/$tag/posts', queryParameters: {'page': page});
    return response.data;
  }
}
