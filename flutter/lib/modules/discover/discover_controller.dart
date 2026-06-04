import 'package:get/get.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/services/post_service.dart';

class DiscoverController extends GetxController {
  final SearchRepository _repo = SearchRepository();
  final PostService _postService = Get.find<PostService>();

  final trending = <Map<String, dynamic>>[].obs;
  final recommended = <PostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    _postService.registerList(recommended);
    loadData();
  }

  @override
  void onClose() {
    _postService.unregisterList(recommended);
    super.onClose();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    _page = 1;
    hasMore.value = true;
    try {
      final results = await Future.wait([
        _repo.getTrending(),
        _repo.getRecommended(page: 1),
      ]);
      trending.value = results[0] as List<Map<String, dynamic>>;
      recommended.value = results[1] as List<PostModel>;
      hasMore.value = recommended.length >= 20;
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      _page++;
      final more = await _repo.getRecommended(page: _page);
      recommended.addAll(more);
      hasMore.value = more.length >= 20;
    } catch (_) {
      _page--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> toggleLike(PostModel post) => _postService.toggleLike(post);
  Future<void> toggleBookmark(PostModel post) => _postService.toggleBookmark(post);
}
