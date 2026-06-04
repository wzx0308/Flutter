import 'package:get/get.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/services/post_service.dart';

class ChannelController extends GetxController {
  final PostRepository _repo = PostRepository();
  final PostService _postService = Get.find<PostService>();
  final posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int _page = 1;
  late final String tag;

  @override
  void onInit() {
    super.onInit();
    tag = Get.parameters['tag'] ?? '';
    _postService.registerList(posts);
    loadPosts();
  }

  @override
  void onClose() {
    _postService.unregisterList(posts);
    super.onClose();
  }

  Future<void> loadPosts() async {
    _page = 1;
    isLoading.value = true;
    hasMore.value = true;
    try {
      final result = await _repo.getPosts(tag: tag, page: 1, pageSize: 20);
      posts.value = result;
      hasMore.value = result.length >= 20;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      _page++;
      final result = await _repo.getPosts(tag: tag, page: _page, pageSize: 20);
      posts.addAll(result);
      hasMore.value = result.length >= 20;
    } catch (e) {
      _page--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> toggleLike(PostModel post) => _postService.toggleLike(post);
  Future<void> toggleBookmark(PostModel post) => _postService.toggleBookmark(post);
}

class ChannelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChannelController());
  }
}
