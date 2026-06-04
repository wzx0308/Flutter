import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/search_provider.dart';

class SearchRepository {
  final SearchProvider _provider = SearchProvider();

  Future<Map<String, dynamic>> search(String query, {String? type, int page = 1}) async {
    final res = await _provider.search(query, type: type, page: page);
    if (res['code'] == 0) {
      final data = res['data'];
      return {
        'users': (data['users'] as List?)?.map((e) => UserModel.fromJson(e)).toList() ?? [],
        'posts': (data['posts'] as List?)?.map((e) => PostModel.fromJson(e)).toList() ?? [],
      };
    }
    throw Exception(res['message'] ?? '搜索失败');
  }

  Future<List<Map<String, dynamic>>> getTrending() async {
    final res = await _provider.getTrending();
    if (res['code'] == 0) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    throw Exception(res['message'] ?? '加载失败');
  }

  Future<List<PostModel>> getRecommended({int page = 1}) async {
    final res = await _provider.getRecommended(page: page);
    if (res['code'] == 0) {
      final list = res['data'] as List;
      return list.map((e) => PostModel.fromJson(e)).toList();
    }
    throw Exception(res['message'] ?? '加载失败');
  }

  Future<List<PostModel>> getTagPosts(String tag, {int page = 1}) async {
    final res = await _provider.getTagPosts(tag, page: page);
    if (res['code'] == 0) {
      final list = res['data'] as List;
      return list.map((e) => PostModel.fromJson(e)).toList();
    }
    throw Exception(res['message'] ?? '加载失败');
  }
}
