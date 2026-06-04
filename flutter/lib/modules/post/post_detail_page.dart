import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'post_detail_controller.dart';
import '../../data/models/comment_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/routes/app_routes.dart';
import '../../core/utils/tag_text_utils.dart';
import '../widgets/report_dialog.dart';

class PostDetailPage extends GetView<PostDetailController> {
  const PostDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('post_detail'.tr),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'report' && controller.post.value != null) {
                ReportDialog.show(context, targetType: 'POST', targetId: controller.post.value!.id);
              }
            },
            itemBuilder: (_) => [PopupMenuItem(value: 'report', child: Text('report'.tr))],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.post.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final post = controller.post.value;
        if (post == null) return Center(child: Text('post_not_found'.tr));
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(post, textColor, subTextColor),
                    _buildContent(post, textColor),
                    if (post.images != null && post.images!.isNotEmpty) _buildImages(post),
                    _buildActions(post, textColor),
                    Divider(thickness: 8, color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5)),
                    _buildComments(textColor, subTextColor),
                  ],
                ),
              ),
            ),
            _buildInputBar(context, cardColor, textColor),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(dynamic post, Color textColor, Color? subTextColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (post.author?.id != null) {
                Get.toNamed('${AppRoutes.userDetail}/${post.author!.id}');
              }
            },
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: post.author?.avatar != null ? NetworkImage(post.author!.avatar!) : null,
              child: post.author?.avatar == null
                  ? Text((post.author?.nickname ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (post.author?.id != null) {
                      Get.toNamed('${AppRoutes.userDetail}/${post.author!.id}');
                    }
                  },
                  child: Text(post.author?.displayName ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
                ),
                if (post.createdAt != null) Text(_formatTime(post.createdAt!), style: TextStyle(color: subTextColor, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic post, Color textColor) {
    final isDark = Get.isDarkMode;
    final tagColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.title != null && post.title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(post.title ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            ),
          if (post.content != null && post.content!.isNotEmpty)
            RichText(
              text: TextSpan(
                children: buildTaggedTextSpans(
                  text: post.content!,
                  normalStyle: TextStyle(fontSize: 16, height: 1.6, color: textColor),
                  tagStyle: TextStyle(fontSize: 16, height: 1.6, color: tagColor, fontWeight: FontWeight.w600),
                  onTagTap: (tag) => Get.toNamed(AppRoutes.search, arguments: {'query': '#$tag'}),
                ),
              ),
            ),
          if (post.tags != null && post.tags!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final tag in post.tags!)
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.search, arguments: {'query': '#$tag'}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('#$tag', style: TextStyle(fontSize: 13, color: tagColor, fontWeight: FontWeight.w500)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImages(dynamic post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: post.images.length == 1 ? 1 : (post.images.length == 4 ? 2 : 3),
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: post.images.length,
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(post.images[i], fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildActions(dynamic post, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _actionBtn(
            icon: post.isLiked == true ? Icons.favorite : Icons.favorite_border,
            color: post.isLiked == true ? Colors.red : Colors.grey,
            text: '${post.likeCount ?? 0}',
            onTap: controller.toggleLike,
          ),
          _actionBtn(icon: Icons.chat_bubble_outline, text: '${post.commentCount ?? 0}'),
          _actionBtn(icon: Icons.share_outlined, text: '${post.shareCount ?? 0}'),
          const Spacer(),
          _actionBtn(
            icon: post.isBookmarked == true ? Icons.bookmark : Icons.bookmark_border,
            color: post.isBookmarked == true ? const Color(0xFFFF9800) : Colors.grey,
            onTap: controller.toggleBookmark,
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({required IconData icon, Color? color, String? text, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? Colors.grey),
            if (text != null) ...[const SizedBox(width: 4), Text(text, style: TextStyle(color: color ?? Colors.grey, fontSize: 14))],
          ],
        ),
      ),
    );
  }

  Widget _buildComments(Color textColor, Color? subTextColor) {
    return Obx(() {
      if (controller.isLoadingComments.value) {
        return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('comments_section'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          ),
          if (controller.comments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('no_comments'.tr, style: TextStyle(color: subTextColor))),
            )
          else
            ...controller.comments.map((c) => _buildCommentItem(c, textColor, subTextColor)),
        ],
      );
    });
  }

  Widget _buildCommentItem(CommentModel comment, Color textColor, Color? subTextColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (comment.author?.id != null) {
                Get.toNamed('${AppRoutes.userDetail}/${comment.author!.id}');
              }
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: comment.author?.avatar != null && comment.author!.avatar!.isNotEmpty
                  ? NetworkImage(comment.author!.avatar!)
                  : null,
              child: (comment.author?.avatar == null || comment.author!.avatar!.isEmpty)
                  ? Text((comment.author?.nickname ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 13))
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (comment.author?.id != null) {
                      Get.toNamed('${AppRoutes.userDetail}/${comment.author!.id}');
                    }
                  },
                  child: Text(comment.author?.displayName ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                ),
                const SizedBox(height: 4),
                Text(comment.content ?? '', style: TextStyle(fontSize: 14, color: textColor)),
                const SizedBox(height: 4),
                Text(_formatTime(comment.createdAt ?? ''), style: TextStyle(color: subTextColor, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
              const SizedBox(width: 2),
              Text('${comment.likeCount ?? 0}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, Color cardColor, Color textColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: Get.isDarkMode ? Colors.grey[800]! : const Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'write_comment'.tr,
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                filled: true,
                fillColor: Get.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  controller.addComment(v.trim());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just_now'.tr;
    if (diff.inHours < 1) return '${diff.inMinutes}${'minutes_ago'.tr}';
    if (diff.inDays < 1) return '${diff.inHours}${'hours_ago'.tr}';
    if (diff.inDays < 30) return '${diff.inDays}${'days_ago'.tr}';
    return '${dt.month}-${dt.day}';
  }
}
