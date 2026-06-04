import 'package:get/get.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/services/post_service.dart';

class FeedController extends GetxController {
  final PostRepository _repo = PostRepository();
  final PostService _postService = Get.find<PostService>();

  final posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    _postService.registerList(posts);
    loadPosts();
  }

  @override
  void onClose() {
    _postService.unregisterList(posts);
    super.onClose();
  }

  Future<void> loadPosts() async {
    if (isLoading.value) return;
    isLoading.value = true;
    _page = 1;
    try {
      final list = await _repo.getPosts(page: 1);
      posts.value = list;
      hasMore.value = list.length >= 20;
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      _page++;
      final list = await _repo.getPosts(page: _page);
      posts.addAll(list);
      hasMore.value = list.length >= 20;
    } catch (_) {
      _page--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> toggleLike(PostModel post) => _postService.toggleLike(post);
  Future<void> toggleBookmark(PostModel post) => _postService.toggleBookmark(post);
}
