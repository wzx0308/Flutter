import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../providers/post_provider.dart';

class PostRepository {
  final PostProvider _provider = PostProvider();

  Future<PostModel> createPost(Map<String, dynamic> data) async {
    final res = await _provider.createPost(data);
    if (res['code'] == 0) {
      return PostModel.fromJson(res['data']);
    }
    throw Exception(res['message'] ?? '发布失败');
  }

  Future<List<PostModel>> getPosts({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? authorId,
    String? tag,
  }) async {
    final res = await _provider.getPosts(
      page: page,
      pageSize: pageSize,
      type: type,
      authorId: authorId,
      tag: tag,
    );
    if (res['code'] == 0) {
      final data = res['data'];
      final list = data is Map ? (data['items'] ?? []) : data;
      return (list as List).map((e) => PostModel.fromJson(e)).toList();
    }
    throw Exception(res['message'] ?? '加载失败');
  }

  Future<PostModel> getPost(String id) async {
    final res = await _provider.getPost(id);
    if (res['code'] == 0) {
      return PostModel.fromJson(res['data']);
    }
    throw Exception(res['message'] ?? '加载失败');
  }

  Future<void> deletePost(String id) async {
    final res = await _provider.deletePost(id);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '删除失败');
    }
  }

  Future<void> likePost(String postId) async {
    final res = await _provider.likePost(postId);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '操作失败');
    }
  }

  Future<void> unlikePost(String postId) async {
    final res = await _provider.unlikePost(postId);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '操作失败');
    }
  }

  Future<List<CommentModel>> getComments(String postId, {int page = 1}) async {
    final res = await _provider.getComments(postId, page: page);
    if (res['code'] == 0) {
      final data = res['data'];
      final list = data is Map ? (data['list'] ?? []) : data;
      return (list as List).map((e) => CommentModel.fromJson(e)).toList();
    }
    throw Exception(res['message'] ?? '加载失败');
  }

  Future<CommentModel> createComment(String postId, String content, {String? parentId}) async {
    final res = await _provider.createComment(postId, content, parentId: parentId);
    if (res['code'] == 0) {
      return CommentModel.fromJson(res['data']);
    }
    throw Exception(res['message'] ?? '评论失败');
  }
}
