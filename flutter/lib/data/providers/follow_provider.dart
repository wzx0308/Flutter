import '../../core/network/api_client.dart';
import '../../core/storage/storage_service.dart';

class FollowProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> toggleFollow(String userId) async {
    final response = await _api.dio.post('/users/$userId/follow');
    return response.data;
  }

  Future<Map<String, dynamic>> unfollow(String userId) async {
    final response = await _api.dio.delete('/users/$userId/follow');
    return response.data;
  }

  Future<Map<String, dynamic>> getFollowers(String userId, {int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get('/users/$userId/followers', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getFollowing(String userId, {int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get('/users/$userId/following', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getFriends({int page = 1, int pageSize = 20}) async {
    final userId = StorageService.to.getUser()?['id'];
    if (userId == null) throw Exception('User not logged in');
    final response = await _api.dio.get('/users/$userId/friends', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> searchUsers(String keyword, {int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get('/users/search', queryParameters: {
      'keyword': keyword,
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }
}
