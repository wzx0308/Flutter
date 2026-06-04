import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';
import '../../core/network/api_client.dart';
import '../../data/providers/follow_provider.dart';
import '../../data/providers/bookmark_provider.dart';
import '../../data/repositories/post_repository.dart';
import '../../core/storage/storage_service.dart';
import '../home/home_controller.dart';

class UserDetailController extends GetxController {
  final ApiClient api = ApiClient();
  final FollowProvider _followProvider = FollowProvider();
  final BookmarkProvider _bookmarkProvider = BookmarkProvider();
  final PostRepository _postRepo = PostRepository();

  final user = Rxn<UserModel>();
  final posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingPosts = false.obs;
  final isFollowing = false.obs;
  final isMutualFollow = false.obs;
  final currentUserId = ''.obs;
  int _page = 1;
  final hasMore = true.obs;
  late final String userId;

  bool get isSelf => currentUserId.value == userId;

  @override
  void onInit() {
    super.onInit();
    userId = Get.parameters['id'] ?? '';
    _loadCurrentUser();
    loadUser();
    loadPosts();
  }

  void _loadCurrentUser() {
    final token = StorageService.to.getToken();
    if (token != null) {
      api.dio.get('/users/me').then((res) {
        if (res.data['code'] == 0) {
          final data = res.data['data'];
          currentUserId.value = data['id'] ?? '';
          _checkFollowStatus();
        }
      }).catchError((_) {});
    }
  }

  Future<void> loadUser() async {
    isLoading.value = true;
    try {
      final res = await api.dio.get('/users/$userId');
      if (res.data['code'] == 0) {
        user.value = UserModel.fromJson(res.data['data']);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPosts() async {
    isLoadingPosts.value = true;
    try {
      final result = await _postRepo.getPosts(authorId: userId, page: 1, pageSize: 20);
      posts.value = result;
      hasMore.value = result.length >= 20;
    } catch (e) {
      // silent
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingPosts.value || !hasMore.value) return;
    isLoadingPosts.value = true;
    try {
      _page++;
      final result = await _postRepo.getPosts(authorId: userId, page: _page, pageSize: 20);
      posts.addAll(result);
      hasMore.value = result.length >= 20;
    } catch (e) {
      _page--;
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> _checkFollowStatus() async {
    if (isSelf || userId.isEmpty) return;
    try {
      final res = await api.dio.get('/users/$userId/mutual-follow-status');
      if (res.data['code'] == 0) {
        final data = res.data['data'];
        isFollowing.value = data['iFollow'] ?? false;
        isMutualFollow.value = data['isMutual'] ?? false;
      }
    } catch (_) {}
  }

  Future<void> toggleFollow() async {
    try {
      final res = isFollowing.value
          ? await _followProvider.unfollow(userId)
          : await _followProvider.toggleFollow(userId);

      if (res['code'] == 0) {
        final data = res['data'];
        isFollowing.value = data['followed'] ?? !isFollowing.value;

        // Update target user's follower count in real-time
        final u = user.value;
        if (u != null && data['targetFollowerCount'] != null) {
          user.value = UserModel(
            id: u.id, username: u.username, nickname: u.nickname,
            avatar: u.avatar, bio: u.bio, email: u.email, phone: u.phone,
            gender: u.gender, birthday: u.birthday, location: u.location,
            role: u.role, status: u.status,
            followerCount: data['targetFollowerCount'],
            followingCount: u.followingCount, postCount: u.postCount,
            createdAt: u.createdAt,
          );
        }

        // Update logged-in user's following count on home profile
        if (data['followerFollowingCount'] != null) {
          _updateHomeUserFollowingCount(data['followerFollowingCount']);
        }

        _checkFollowStatus();
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  void _updateHomeUserFollowingCount(int count) {
    try {
      final homeController = Get.find<HomeController>();
      final u = homeController.user.value;
      if (u != null) {
        homeController.user.value = UserModel(
          id: u.id, username: u.username, nickname: u.nickname,
          avatar: u.avatar, bio: u.bio, email: u.email, phone: u.phone,
          gender: u.gender, birthday: u.birthday, location: u.location,
          role: u.role, status: u.status,
          followerCount: u.followerCount,
          followingCount: count,
          postCount: u.postCount, createdAt: u.createdAt,
        );
      }
    } catch (_) {}
  }

  Future<void> toggleBookmark(PostModel post) async {
    final token = StorageService.to.getToken();
    if (token == null) {
      Get.snackbar('', 'login_required'.tr);
      return;
    }
    final index = posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;
    final old = posts[index];
    final bookmarked = old.isBookmarked == true;
    posts[index] = PostModel(
      id: old.id, authorId: old.authorId, type: old.type,
      content: old.content, title: old.title, coverImage: old.coverImage,
      images: old.images, tags: old.tags, locationName: old.locationName,
      likeCount: old.likeCount, commentCount: old.commentCount,
      shareCount: old.shareCount, status: old.status, createdAt: old.createdAt,
      author: old.author, isLiked: old.isLiked, isBookmarked: !bookmarked,
    );
    try {
      final res = await _bookmarkProvider.toggleBookmark(post.id);
      if (res['code'] == 0) {
        final newBookmarked = res['data']['bookmarked'] ?? !bookmarked;
        posts[index] = PostModel(
          id: old.id, authorId: old.authorId, type: old.type,
          content: old.content, title: old.title, coverImage: old.coverImage,
          images: old.images, tags: old.tags, locationName: old.locationName,
          likeCount: old.likeCount, commentCount: old.commentCount,
          shareCount: old.shareCount, status: old.status, createdAt: old.createdAt,
          author: old.author, isLiked: old.isLiked, isBookmarked: newBookmarked,
        );
        Get.snackbar('', newBookmarked ? 'bookmarked'.tr : 'unbookmarked'.tr,
            snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
      }
    } catch (_) {
      posts[index] = old;
    }
  }
}

class UserDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UserDetailController());
  }
}
