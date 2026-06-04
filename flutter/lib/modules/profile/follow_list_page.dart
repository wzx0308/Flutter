import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'follow_list_controller.dart';
import '../../data/models/user_model.dart';
import '../../app/routes/app_routes.dart';

class FollowListPage extends GetView<FollowListController> {
  const FollowListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    final title = controller.type == 'followers' ? 'fans_count'.tr : 'following_count'.tr;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text(title)),
      body: Obx(() {
        if (controller.isLoading.value && controller.users.isEmpty) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (controller.users.isEmpty) {
          return Center(
            child: Text(
              controller.type == 'followers' ? 'no_followers'.tr : 'no_following'.tr,
              style: TextStyle(color: subTextColor, fontSize: 15),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: controller.users.length + (controller.hasMore.value ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == controller.users.length) {
              controller.loadMore();
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _buildUserItem(controller.users[i], cardColor, textColor, subTextColor, accentColor);
          },
        );
      }),
    );
  }

  Widget _buildUserItem(UserModel user, Color cardColor, Color textColor, Color subTextColor, Color accentColor) {
    return GestureDetector(
      onTap: () => Get.toNamed('${AppRoutes.userDetail}/${user.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: accentColor.withOpacity(0.1),
              backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                  ? NetworkImage(user.avatar!)
                  : null,
              child: (user.avatar == null || user.avatar!.isEmpty)
                  ? Text(
                      user.displayName[0].toUpperCase(),
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        user.bio!,
                        style: TextStyle(color: subTextColor, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
