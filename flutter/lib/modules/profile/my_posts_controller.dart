import 'package:get/get.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/models/post_model.dart';
import '../../data/services/post_service.dart';
import '../../core/storage/storage_service.dart';

class MyPostsController extends GetxController {
  final PostRepository _postRepo = PostRepository();
  final PostService _postService = Get.find<PostService>();
  final posts = <PostModel>[].obs;
  final isLoading = false.obs;

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
    isLoading.value = true;
    try {
      final userData = StorageService.to.getUser();
      final userId = userData?['id'];
      if (userId != null) {
        posts.value = await _postRepo.getPosts(authorId: userId);
      }
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(PostModel post) => _postService.toggleLike(post);
  Future<void> toggleBookmark(PostModel post) => _postService.toggleBookmark(post);
  Future<void> deletePost(PostModel post) => _postService.deletePost(post);
}
