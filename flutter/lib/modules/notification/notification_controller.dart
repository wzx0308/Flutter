import 'package:get/get.dart';
import '../../data/models/notification_model.dart';
import '../../data/providers/notification_provider.dart';

class NotificationController extends GetxController {
  final NotificationProvider _provider = NotificationProvider();
  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;
  final hasMore = true.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    loadUnreadCount();
  }

  Future<void> loadNotifications() async {
    _page = 1;
    isLoading.value = true;
    hasMore.value = true;
    try {
      final res = await _provider.getNotifications(page: 1, pageSize: 20);
      if (res['code'] == 0) {
        final data = res['data'];
        final list = data is Map ? (data['list'] ?? []) : data;
        notifications.value = (list as List).map((e) => NotificationModel.fromJson(e)).toList();
        hasMore.value = notifications.length < (data is Map ? (data['total'] ?? 0) : 0);
      }
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    isLoading.value = true;
    try {
      _page++;
      final res = await _provider.getNotifications(page: _page, pageSize: 20);
      if (res['code'] == 0) {
        final data = res['data'];
        final list = data is Map ? (data['list'] ?? []) : data;
        final more = (list as List).map((e) => NotificationModel.fromJson(e)).toList();
        notifications.addAll(more);
        hasMore.value = more.length >= 20;
      }
    } catch (e) {
      _page--;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final res = await _provider.getUnreadCount();
      if (res['code'] == 0) {
        unreadCount.value = res['data']['count'] ?? 0;
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _provider.markAllRead();
      for (var i = 0; i < notifications.length; i++) {
        final n = notifications[i];
        notifications[i] = NotificationModel(
          id: n.id, userId: n.userId, actorId: n.actorId,
          type: n.type, targetType: n.targetType, targetId: n.targetId,
          content: n.content, isRead: true, createdAt: n.createdAt, actor: n.actor,
        );
      }
      unreadCount.value = 0;
    } catch (_) {}
  }
}
