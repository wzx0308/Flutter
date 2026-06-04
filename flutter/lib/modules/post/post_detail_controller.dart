import 'package:get/get.dart';
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/providers/bookmark_provider.dart';
import '../../data/services/post_service.dart';
import '../../core/storage/storage_service.dart';

class PostDetailController extends GetxController {
  final PostRepository _repo = PostRepository();
  final BookmarkProvider _bookmarkProvider = BookmarkProvider();
  final PostService _postService = Get.find<PostService>();

  final post = Rxn<PostModel>();
  final comments = <CommentModel>[].obs;
  final isLoading = false.obs;
  final isLoadingComments = false.obs;
  late final String postId;

  @override
  void onInit() {
    super.onInit();
    postId = Get.parameters['id'] ?? '';
    _loadPost();
    _loadComments();
    _recordView();
  }

  Future<void> _loadPost() async {
    isLoading.value = true;
    try {
      post.value = await _repo.getPost(postId);
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadComments() async {
    isLoadingComments.value = true;
    try {
      comments.value = await _repo.getComments(postId);
    } catch (_) {} finally {
      isLoadingComments.value = false;
    }
  }

  void _recordView() async {
    final token = StorageService.to.getToken();
    if (token == null) return;
    try {
      await _bookmarkProvider.recordView(postId);
    } catch (_) {}
  }

  /// Single API call via PostService, updates detail + all lists
  Future<void> toggleLike() async {
    final p = post.value;
    if (p == null) return;
    final updated = await _postService.toggleLike(p);
    post.value = updated;
  }

  /// Single API call via PostService, updates detail + all lists
  Future<void> toggleBookmark() async {
    final p = post.value;
    if (p == null) return;
    final updated = await _postService.toggleBookmark(p);
    post.value = updated;
  }

  Future<void> addComment(String content, {String? parentId}) async {
    try {
      final comment = await _repo.createComment(postId, content, parentId: parentId);
      comments.insert(0, comment);
      final p = post.value;
      if (p != null) {
        final newCount = (p.commentCount ?? 0) + 1;
        final updated = PostModel(
          id: p.id, authorId: p.authorId, type: p.type,
          content: p.content, title: p.title, coverImage: p.coverImage,
          images: p.images, tags: p.tags, locationName: p.locationName,
          likeCount: p.likeCount, commentCount: newCount,
          shareCount: p.shareCount, status: p.status, createdAt: p.createdAt,
          author: p.author, isLiked: p.isLiked, isBookmarked: p.isBookmarked,
        );
        post.value = updated;
        _postService.updatePostField(postId, (_) => updated);
      }
    } catch (e) {
      Get.snackbar('失败', '评论失败');
    }
  }
}
