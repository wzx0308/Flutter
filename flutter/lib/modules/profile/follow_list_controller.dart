import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/follow_provider.dart';

class FollowListController extends GetxController {
  final FollowProvider _followProvider = FollowProvider();

  final users = <UserModel>[].obs;
  final isLoading = false.obs;
  final hasMore = true.obs;
  int _page = 1;

  late final String userId;
  late final String type; // 'followers' or 'following'

  @override
  void onInit() {
    super.onInit();
    userId = Get.arguments['userId'] ?? '';
    type = Get.arguments['type'] ?? 'followers';
    loadUsers();
  }

  Future<void> loadUsers() async {
    _page = 1;
    isLoading.value = true;
    hasMore.value = true;
    try {
      final res = type == 'followers'
          ? await _followProvider.getFollowers(userId, page: 1, pageSize: 20)
          : await _followProvider.getFollowing(userId, page: 1, pageSize: 20);
      if (res['code'] == 0) {
        final data = res['data'];
        final list = data is Map ? (data['list'] ?? []) : data;
        users.value = (list as List).map((e) => UserModel.fromJson(e)).toList();
        hasMore.value = users.length < (data is Map ? (data['total'] ?? 0) : 0);
      }
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    isLoading.value = true;
    try {
      _page++;
      final res = type == 'followers'
          ? await _followProvider.getFollowers(userId, page: _page, pageSize: 20)
          : await _followProvider.getFollowing(userId, page: _page, pageSize: 20);
      if (res['code'] == 0) {
        final data = res['data'];
        final list = data is Map ? (data['list'] ?? []) : data;
        final more = (list as List).map((e) => UserModel.fromJson(e)).toList();
        users.addAll(more);
        hasMore.value = more.length >= 20;
      }
    } catch (e) {
      _page--;
    } finally {
      isLoading.value = false;
    }
  }
}
