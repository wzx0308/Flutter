import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../data/models/post_model.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/tag_text_utils.dart';
import '../../../app/routes/app_routes.dart';
import '../../widgets/report_dialog.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onTap;
  final VoidCallback? onComment;
  final VoidCallback? onBookmark;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onTap,
    this.onComment,
    this.onBookmark,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);
    final titleBgColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[50]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, textColor, subTextColor, accentColor),
              _buildContent(textColor),
              _buildTags(accentColor),
              if (post.isArticle) _buildTitle(titleBgColor, accentColor),
              _buildImages(),
              _buildActions(subTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, Color subTextColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (post.author?.id != null) {
                Get.toNamed('${AppRoutes.userDetail}/${post.author!.id}');
              }
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: accentColor.withOpacity(0.1),
              backgroundImage: post.author?.avatar != null ? NetworkImage(post.author!.avatar!) : null,
              child: post.author?.avatar == null
                  ? Text(
                      (post.author?.nickname ?? post.author?.username ?? 'U')[0].toUpperCase(),
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
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
                  child: Text(
                    post.author?.displayName ?? 'Unknown',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                  ),
                ),
                if (post.createdAt != null)
                  Text(
                    _formatTime(post.createdAt!),
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: subTextColor),
            onSelected: (v) {
              if (v == 'report') {
                ReportDialog.show(context, targetType: 'POST', targetId: post.id);
              } else if (v == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (_) => [
              if (onDelete != null)
                PopupMenuItem(value: 'delete', child: Text('delete_post'.tr, style: const TextStyle(color: Colors.red))),
              PopupMenuItem(value: 'report', child: Text('report'.tr)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    if (post.content == null || post.content!.isEmpty) return const SizedBox.shrink();
    final isDark = Get.isDarkMode;
    final tagColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: RichText(
        maxLines: post.isArticle ? 3 : 10,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: buildTaggedTextSpans(
            text: post.content!,
            normalStyle: TextStyle(fontSize: 15, height: 1.5, color: textColor),
            tagStyle: TextStyle(fontSize: 15, height: 1.5, color: tagColor, fontWeight: FontWeight.w600),
            onTagTap: (tag) => Get.toNamed(AppRoutes.search, arguments: {'query': '#$tag'}),
          ),
        ),
      ),
    );
  }

  Widget _buildTags(Color accentColor) {
    if (post.tags == null || post.tags!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: <Widget>[
          for (final tag in post.tags!)
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.search, arguments: {'query': '#$tag'}),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle(Color titleBgColor, Color accentColor) {
    if (post.title == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: titleBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.article_outlined, size: 20, color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                post.title!,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: accentColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImages() {
    if (post.images == null || post.images!.isEmpty) return const SizedBox.shrink();
    final images = post.images!;
    final count = images.length > 9 ? 9 : images.length;
    // 图片尺寸与发布页预览保持一致：80.w
    final imageSize = 80.w;
    final spacing = 8.w;
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(count, (i) {
          return SizedBox(
            width: imageSize,
            height: imageSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.network(
                images[i],
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (ctx, error, stack) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: imageSize * 0.3),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActions(Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: [
          _actionBtn(
            icon: post.isLiked == true ? Icons.favorite : Icons.favorite_border,
            color: post.isLiked == true ? Colors.red : subTextColor,
            text: '${post.likeCount ?? 0}',
            onTap: onLike,
          ),
          _actionBtn(
            icon: Icons.chat_bubble_outline,
            text: '${post.commentCount ?? 0}',
            onTap: onComment,
          ),
          _actionBtn(icon: Icons.share_outlined, text: '${post.shareCount ?? 0}', color: subTextColor),
          const Spacer(),
          _actionBtn(
            icon: post.isBookmarked == true ? Icons.bookmark : Icons.bookmark_border,
            color: post.isBookmarked == true ? const Color(0xFFFF9800) : subTextColor,
            onTap: () {
              final token = StorageService.to.getToken();
              if (token == null) {
                Get.snackbar('', 'login_required'.tr);
                return;
              }
              onBookmark?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    Color? color,
    String? text,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey),
            if (text != null) ...[
              const SizedBox(width: 4),
              Text(text, style: TextStyle(color: color ?? Colors.grey, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.defaultDialog(
      title: 'delete_post'.tr,
      middleText: 'confirm_delete_post'.tr,
      textConfirm: 'confirm_btn'.tr,
      textCancel: 'cancel_btn'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        onDelete?.call();
      },
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
