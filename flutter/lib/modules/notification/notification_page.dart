import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'notification_controller.dart';
import '../../app/routes/app_routes.dart';

class NotificationPage extends GetView<NotificationController> {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('notifications'.tr),
        actions: [
          TextButton(
            onPressed: controller.markAllRead,
            child: Text('mark_all_read'.tr, style: TextStyle(color: accentColor, fontSize: 13.sp)),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64.r, color: Colors.grey[300]),
                SizedBox(height: 16.h),
                Text('no_notifications'.tr, style: TextStyle(color: subTextColor, fontSize: 16.sp)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadNotifications,
          color: accentColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: controller.notifications.length + (controller.hasMore.value ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == controller.notifications.length) {
                controller.loadMore();
                return Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final n = controller.notifications[i];
              return _buildNotificationItem(n, cardColor, textColor, subTextColor, accentColor, isDark);
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationItem(dynamic n, Color cardColor, Color textColor, Color subTextColor, Color accentColor, bool isDark) {
    final actorName = n.actor?.displayName ?? '';
    final actionText = _getActionText(n.type, actorName);

    return GestureDetector(
      onTap: () => _onTapNotification(n),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: accentColor.withOpacity(0.1),
                  backgroundImage: n.actor?.avatar != null ? NetworkImage(n.actor!.avatar!) : null,
                  child: n.actor?.avatar == null
                      ? Text(actorName.isNotEmpty ? actorName[0].toUpperCase() : 'U', style: TextStyle(color: accentColor, fontSize: 14.sp))
                      : null,
                ),
                if (!n.isRead)
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 8.r, height: 8.r,
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(actionText, style: TextStyle(fontSize: 14.sp, color: textColor)),
                  if (n.content != null && n.content!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(n.content!, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.sp, color: subTextColor)),
                  ],
                  SizedBox(height: 4.h),
                  Text(_formatTime(n.createdAt), style: TextStyle(fontSize: 12.sp, color: subTextColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActionText(String? type, String actorName) {
    switch (type) {
      case 'FOLLOW': return 'follow_notification'.trParams({'name': actorName});
      case 'LIKE': return 'like_notification'.trParams({'name': actorName});
      case 'BOOKMARK': return 'bookmark_notification'.trParams({'name': actorName});
      case 'COMMENT': return 'comment_notification'.trParams({'name': actorName});
      case 'REPORT_RESOLVED': return 'report_resolved_notification'.tr;
      default: return '';
    }
  }

  void _onTapNotification(dynamic n) {
    switch (n.targetType) {
      case 'User':
        Get.toNamed('${AppRoutes.userDetail}/${n.targetId}');
        break;
      case 'Post':
        Get.toNamed('${AppRoutes.postDetail}/${n.targetId}');
        break;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
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
