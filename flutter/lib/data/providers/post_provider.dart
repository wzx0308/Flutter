import '../../core/network/api_client.dart';

class PostProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    final response = await _api.dio.post('/posts', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? authorId,
    String? tag,
  }) async {
    final response = await _api.dio.get('/posts', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (type != null) 'type': type,
      if (authorId != null) 'authorId': authorId,
      if (tag != null) 'tag': tag,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getPost(String id) async {
    final response = await _api.dio.get('/posts/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> updatePost(String id, Map<String, dynamic> data) async {
    final response = await _api.dio.patch('/posts/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deletePost(String id) async {
    final response = await _api.dio.delete('/posts/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    final response = await _api.dio.post('/posts/$postId/like');
    return response.data;
  }

  Future<Map<String, dynamic>> unlikePost(String postId) async {
    final response = await _api.dio.delete('/posts/$postId/like');
    return response.data;
  }

  Future<Map<String, dynamic>> getComments(String postId, {int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get('/posts/$postId/comments', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createComment(String postId, String content, {String? parentId}) async {
    final response = await _api.dio.post('/posts/$postId/comments', data: {
      'content': content,
      if (parentId != null) 'parentId': parentId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> deleteComment(String commentId) async {
    final response = await _api.dio.delete('/comments/$commentId');
    return response.data;
  }
}
