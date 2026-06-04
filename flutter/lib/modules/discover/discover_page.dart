import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'discover_controller.dart';
import '../../app/theme/app_colors.dart';
import '../../app/routes/app_routes.dart';
import '../feed/widgets/post_card.dart';

class DiscoverPage extends GetView<DiscoverController> {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.search),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                Text('search_hint'.tr, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.recommended.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        // Header count = trending section (1 if trending exists) + 1 for title
        final headerCount = controller.trending.isNotEmpty ? 2 : 1;
        final postCount = controller.recommended.length;
        final total = headerCount + postCount + (controller.hasMore.value ? 1 : 0);

        return RefreshIndicator(
          onRefresh: controller.loadData,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 80),
            itemCount: total,
            itemBuilder: (_, i) {
              // Trending section header
              if (i == 0 && controller.trending.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('trending_topics'.tr, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
                );
              }
              // Trending chips
              if (i == 1 && controller.trending.isNotEmpty) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.trending.map((t) {
                      final chipAccent = isDark ? const Color(0xFF8B7FD4) : AppColors.primary;
                      return GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.search, arguments: {'query': '#${t['tag']}'}),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: chipAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text('#${t['tag']}', style: TextStyle(color: chipAccent, fontWeight: FontWeight.w500)),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
              // Recommended title (when no trending)
              if (i == 0 && controller.trending.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('recommended_content'.tr, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
                );
              }
              // Load more indicator
              final postIndex = i - headerCount;
              if (postIndex >= postCount) {
                controller.loadMore();
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              // "No more" message
              if (!controller.hasMore.value && postIndex == postCount - 1 && postCount > 0) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text('没有更多了~', style: TextStyle(color: subTextColor, fontSize: 13))),
                );
              }
              // Post card
              final post = controller.recommended[postIndex];
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
