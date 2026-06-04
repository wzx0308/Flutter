import 'package:get/get.dart';
import '../../data/models/post_model.dart';
import '../../data/providers/bookmark_provider.dart';
import '../../data/services/post_service.dart';
import '../../core/storage/storage_service.dart';

class MyBookmarksController extends GetxController {
  final BookmarkProvider _bookmarkProvider = BookmarkProvider();
  final PostService _postService = Get.find<PostService>();

  final posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final hasMore = true.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    _postService.registerList(posts);
    loadBookmarks();
  }

  @override
  void onClose() {
    _postService.unregisterList(posts);
    super.onClose();
  }

  Future<void> loadBookmarks() async {
    _page = 1;
    isLoading.value = true;
    hasMore.value = true;
    try {
      final res = await _bookmarkProvider.getMyBookmarks(page: 1, pageSize: 20);
      if (res['code'] == 0) {
        final data = res['data'];
        final list = data is Map ? (data['list'] ?? []) : data;
        posts.value = (list as List).map((e) => PostModel.fromJson(e)).toList();
        hasMore.value = posts.length < (data is Map ? (data['total'] ?? 0) : 0);
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
      final res = await _bookmarkProvider.getMyBookmarks(page: _page, pageSize: 20);
      if (res['code'] == 0) {
        final data = res['data'];
        final list = data is Map ? (data['list'] ?? []) : data;
        final more = (list as List).map((e) => PostModel.fromJson(e)).toList();
        posts.addAll(more);
        hasMore.value = more.length >= 20;
      }
    } catch (e) {
      _page--;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(PostModel post) => _postService.toggleLike(post);
  Future<void> toggleBookmark(PostModel post) async {
    await _postService.toggleBookmark(post);
    // Remove unbookmarked posts from bookmarks list
    final idx = posts.indexWhere((p) => p.id == post.id);
    if (idx != -1 && posts[idx].isBookmarked != true) {
      posts.removeAt(idx);
    }
  }
}
