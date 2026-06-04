import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'my_bookmarks_controller.dart';
import '../../app/routes/app_routes.dart';
import '../feed/widgets/post_card.dart';

class MyBookmarksPage extends GetView<MyBookmarksController> {
  const MyBookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text('my_favorites'.tr)),
      body: Obx(() {
        if (controller.isLoading.value && controller.posts.isEmpty) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (controller.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('no_favorites'.tr, style: TextStyle(color: subTextColor, fontSize: 15)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadBookmarks,
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
                onBookmark: () => controller.toggleBookmark(post),
              );
            },
          ),
        );
      }),
    );
  }
}
