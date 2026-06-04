import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'my_posts_controller.dart';
import '../../app/routes/app_routes.dart';
import '../feed/widgets/post_card.dart';

class MyPostsPage extends GetView<MyPostsController> {
  const MyPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('my_posts'.tr),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.posts.isEmpty) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (controller.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('no_posts_yet'.tr, style: TextStyle(color: subTextColor, fontSize: 15)),
                const SizedBox(height: 8),
                Text('go_check_home'.tr, style: TextStyle(color: subTextColor, fontSize: 13)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadPosts,
          color: accentColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: controller.posts.length,
            itemBuilder: (_, i) {
              final post = controller.posts[i];
              return PostCard(
                post: post,
                onLike: () => controller.toggleLike(post),
                onTap: () => Get.toNamed('${AppRoutes.postDetail}/${post.id}'),
                onBookmark: () => controller.toggleBookmark(post),
                onDelete: () => controller.deletePost(post),
              );
            },
          ),
        );
      }),
    );
  }
}
