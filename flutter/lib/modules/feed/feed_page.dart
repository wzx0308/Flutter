import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'feed_controller.dart';
import 'widgets/post_card.dart';
import '../../app/routes/app_routes.dart';

class FeedPage extends GetView<FeedController> {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Obx(() {
      if (controller.isLoading.value && controller.posts.isEmpty) {
        return Center(child: CircularProgressIndicator(color: accentColor));
      }
      if (controller.posts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.feed_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('no_posts'.tr, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 16)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.createPost),
                child: Text('create_first_post'.tr, style: TextStyle(color: accentColor)),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.loadPosts,
        color: accentColor,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: controller.posts.length + (controller.hasMore.value ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == controller.posts.length) {
              controller.loadMore();
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final post = controller.posts[i];
            return PostCard(
              post: post,
              onLike: () => controller.toggleLike(post),
              onTap: () => Get.toNamed('${AppRoutes.postDetail}/${post.id}'),
              onComment: () => _showComments(context, post.id),
              onBookmark: () => controller.toggleBookmark(post),
            );
          },
        ),
      );
    });
  }

  void _showComments(BuildContext context, String postId) {
    final isDark = Get.isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: _CommentSheet(postId: postId),
      ),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  final String postId;
  const _CommentSheet({required this.postId});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _controller = TextEditingController();
  final _comments = <dynamic>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final fillColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]!;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('comments_section'.tr, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor)),
        ),
        Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _comments.isEmpty
                  ? Center(child: Text('no_comments'.tr, style: TextStyle(color: subTextColor)))
                  : ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder: (_, i) => const ListTile(title: Text('comment')),
                    ),
        ),
        Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'comment_hint'.tr,
                    hintStyle: TextStyle(color: subTextColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.r)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    filled: true,
                    fillColor: fillColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.send, color: accentColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
