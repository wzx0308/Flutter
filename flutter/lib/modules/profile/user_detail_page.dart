import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'user_detail_controller.dart';
import '../../app/routes/app_routes.dart';
import '../feed/widgets/post_card.dart';

class UserDetailPage extends GetView<UserDetailController> {
  const UserDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Obx(() => Text(controller.user.value?.displayName ?? '')),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF212121),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        final user = controller.user.value;
        if (user == null) {
          return Center(child: Text('user_not_found'.tr));
        }
        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadUser();
            await controller.loadPosts();
          },
          color: accentColor,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(user, textColor, subTextColor, accentColor, cardColor, isDark)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('user_posts'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                ),
              ),
              if (controller.isLoadingPosts.value && controller.posts.isEmpty)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (controller.posts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text('no_posts_yet'.tr, style: TextStyle(color: subTextColor)),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i == controller.posts.length) {
                        controller.loadMorePosts();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final post = controller.posts[i];
                      return PostCard(
                        post: post,
                        onLike: () {},
                        onTap: () => Get.toNamed('${AppRoutes.postDetail}/${post.id}'),
                        onComment: () {},
                        onBookmark: () => controller.toggleBookmark(post),
                      );
                    },
                    childCount: controller.posts.length + (controller.hasMore.value ? 1 : 0),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(dynamic user, Color textColor, Color subTextColor, Color accentColor, Color cardColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: accentColor.withOpacity(0.1),
            backgroundImage: user.avatar != null && user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
            child: user.avatar == null || user.avatar.isEmpty
                ? Text(
                    (user.displayName)[0].toUpperCase(),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            user.displayName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
          ),
          if (user.bio != null && user.bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              user.bio,
              style: TextStyle(fontSize: 13, color: subTextColor),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.followList, arguments: {'userId': user.id, 'type': 'followers'}),
                child: _statItem('${user.followerCount ?? 0}', 'fans_count'.tr, textColor, subTextColor),
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.followList, arguments: {'userId': user.id, 'type': 'following'}),
                child: _statItem('${user.followingCount ?? 0}', 'following_count'.tr, textColor, subTextColor),
              ),
              const SizedBox(width: 32),
              _statItem('${user.postCount ?? 0}', 'posts_count'.tr, textColor, subTextColor),
            ],
          ),
          const SizedBox(height: 16),
          if (!controller.isSelf) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() {
                  final isFollowing = controller.isFollowing.value;
                  final isMutual = controller.isMutualFollow.value;
                  return SizedBox(
                    width: 100,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: controller.toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? (isDark ? Colors.grey[700] : Colors.grey[300])
                            : accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        isMutual ? 'mutual_follow'.tr : (isFollowing ? 'unfollow'.tr : 'follow'.tr),
                        style: TextStyle(
                          color: isFollowing ? textColor : Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        final api = Get.find<UserDetailController>().api;
                        final res = await api.dio.post('/conversations', data: {
                          'type': 'PRIVATE',
                          'userIds': [controller.userId],
                        });
                        if (res.data['code'] == 0) {
                          final conv = res.data['data'];
                          final conversationId = conv['id'];
                          final name = conv['name'] ?? controller.user.value?.displayName;
                          Get.toNamed('${AppRoutes.chatDetail}/$conversationId', arguments: {'name': name});
                        }
                      } catch (e) {
                        Get.snackbar('Error', e.toString());
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accentColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text('send_message'.tr, style: TextStyle(color: accentColor, fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionChip(Icons.call, '语音通话'.tr, () => Get.snackbar('', '语音通话功能开发中'), accentColor),
                const SizedBox(width: 8),
                _actionChip(Icons.videocam, '视频通话'.tr, () => Get.snackbar('', '视频通话功能开发中'), accentColor),
                const SizedBox(width: 8),
                _actionChip(Icons.block, '拉黑'.tr, _confirmBlock, Colors.red),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String count, String label, Color textColor, Color subTextColor) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: subTextColor)),
      ],
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  void _confirmBlock() {
    Get.defaultDialog(
      title: '拉黑用户'.tr,
      middleText: '确定要拉黑该用户吗？拉黑后将无法收到对方的消息'.tr,
      textConfirm: '确定'.tr,
      textCancel: '取消'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        Get.snackbar('', '拉黑功能开发中');
      },
    );
  }
}
