import 'package:get/get.dart';
import '../models/post_model.dart';
import '../repositories/post_repository.dart';
import '../providers/bookmark_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/storage_service.dart';

/// Shared post state service — single source of truth for like/bookmark.
/// All post lists register here. API calls happen ONLY here.
class PostService extends GetxService {
  final PostRepository _postRepo = PostRepository();
  final BookmarkProvider _bookmarkProvider = BookmarkProvider();
  final ApiClient _api = ApiClient();

  final List<RxList<PostModel>> _registeredLists = [];

  void registerList(RxList<PostModel> list) {
    if (!_registeredLists.contains(list)) _registeredLists.add(list);
  }

  void unregisterList(RxList<PostModel> list) {
    _registeredLists.remove(list);
  }

  void _updateAll(String postId, PostModel Function(PostModel) updater) {
    for (final list in _registeredLists) {
      final idx = list.indexWhere((p) => p.id == postId);
      if (idx != -1) list[idx] = updater(list[idx]);
    }
  }

  /// 新帖子发布后，插入到所有已注册列表的顶部
  void notifyPostCreated(PostModel post) {
    for (final list in _registeredLists) {
      // 避免重复
      if (!list.any((p) => p.id == post.id)) {
        list.insert(0, post);
      }
    }
  }

  /// 触发所有已注册列表重新加载
  Future<void> refreshAll() async {
    // 通过重新加载由 PostService 管理的列表
    // 具体刷新逻辑由各 controller 自行处理
  }

  /// Update a post field across all lists (used for comment count sync etc.)
  void updatePostField(String postId, PostModel Function(PostModel) updater) {
    _updateAll(postId, updater);
  }

  /// Delete a post from all registered lists and the backend.
  Future<void> deletePost(PostModel post) async {
    try {
      await _postRepo.deletePost(post.id);
      for (final list in _registeredLists) {
        list.removeWhere((p) => p.id == post.id);
      }
      Get.snackbar('', 'deleted'.tr, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
    } catch (e) {
      Get.snackbar('', 'delete_failed'.tr, snackPosition: SnackPosition.BOTTOM);
    }
  }

  PostModel _build(PostModel p, {int? likeCount, bool? isLiked, int? commentCount, bool? isBookmarked}) {
    return PostModel(
      id: p.id, authorId: p.authorId, type: p.type,
      content: p.content, title: p.title, coverImage: p.coverImage,
      images: p.images, tags: p.tags, locationName: p.locationName,
      likeCount: likeCount ?? p.likeCount,
      commentCount: commentCount ?? p.commentCount,
      shareCount: p.shareCount, status: p.status, createdAt: p.createdAt,
      author: p.author,
      isLiked: isLiked ?? p.isLiked,
      isBookmarked: isBookmarked ?? p.isBookmarked,
    );
  }

  /// Toggle like. Returns the updated PostModel (or original on error).
  Future<PostModel> toggleLike(PostModel post) async {
    final token = StorageService.to.getToken();
    if (token == null) {
      Get.snackbar('', 'login_required'.tr);
      return post;
    }
    final liked = post.isLiked == true;
    final optimistic = _build(post,
      likeCount: (post.likeCount ?? 0) + (liked ? -1 : 1),
      isLiked: !liked,
    );

    // Optimistic update all lists
    _updateAll(post.id, (_) => optimistic);

    try {
      final res = liked
          ? await _api.dio.delete('/posts/${post.id}/like')
          : await _api.dio.post('/posts/${post.id}/like');
      if (res.data['code'] == 0) {
        final data = res.data['data'];
        final confirmed = _build(post,
          likeCount: data['likeCount'] ?? optimistic.likeCount,
          isLiked: data['liked'] ?? !liked,
        );
        _updateAll(post.id, (_) => confirmed);
        return confirmed;
      }
    } catch (_) {}
    // On error, revert
    _updateAll(post.id, (_) => post);
    return post;
  }

  /// Toggle bookmark. Returns the updated PostModel.
  Future<PostModel> toggleBookmark(PostModel post) async {
    final token = StorageService.to.getToken();
    if (token == null) {
      Get.snackbar('', 'login_required'.tr);
      return post;
    }
    final bookmarked = post.isBookmarked == true;
    final optimistic = _build(post, isBookmarked: !bookmarked);

    _updateAll(post.id, (_) => optimistic);

    try {
      final res = await _bookmarkProvider.toggleBookmark(post.id);
      if (res['code'] == 0) {
        final newBookmarked = res['data']['bookmarked'] ?? !bookmarked;
        final confirmed = _build(post, isBookmarked: newBookmarked);
        _updateAll(post.id, (_) => confirmed);
        Get.snackbar('', newBookmarked ? 'bookmarked'.tr : 'unbookmarked'.tr,
            snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
        return confirmed;
      }
    } catch (_) {}
    _updateAll(post.id, (_) => post);
    return post;
  }
}
