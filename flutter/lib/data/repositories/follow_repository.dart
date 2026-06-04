import '../models/user_model.dart';
import '../providers/follow_provider.dart';

class FollowRepository {
  final FollowProvider _provider = FollowProvider();

  Future<bool> toggleFollow(String userId) async {
    final res = await _provider.toggleFollow(userId);
    if (res['code'] == 0) {
      return res['data']['isFollowing'] ?? false;
    }
    throw Exception(res['message'] ?? '操作失败');
  }

  Future<List<UserModel>> getFollowers(String userId, {int page = 1}) async {
    final res = await _provider.getFollowers(userId, page: page);
    if (res['code'] == 0) {
      final list = res['data'] as List;
      return list.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception(res['message'] ?? '加载失败');
  }

  Future<List<UserModel>> getFollowing(String userId, {int page = 1}) async {
    final res = await _provider.getFollowing(userId, page: page);
    if (res['code'] == 0) {
      final list = res['data'] as List;
      return list.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception(res['message'] ?? '加载失败');
  }
}
