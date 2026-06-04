import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'chat_list_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/conversation_model.dart';

class ChatListPage extends GetView<ChatListController> {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Obx(() {
      if (controller.isLoading.value && controller.conversations.isEmpty) {
        return Center(child: CircularProgressIndicator(color: accentColor));
      }
      if (controller.conversations.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('no_conversations'.tr, style: TextStyle(color: subTextColor, fontSize: 16)),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () async => controller.loadConversations(),
        child: ListView.builder(
          itemCount: controller.conversations.length,
          itemBuilder: (_, i) {
            final conv = controller.conversations[i];
            return _buildSlidableItem(conv, cardColor, textColor, subTextColor, accentColor);
          },
        ),
      );
    });
  }

  Widget _buildSlidableItem(ConversationModel conv, Color cardColor, Color textColor, Color subTextColor, Color accentColor) {
    final displayName = conv.name ?? 'unknown_conversation'.tr;

    return Slidable(
      key: ValueKey(conv.id),
      // Only allow end-to-start (right-to-left) swipe
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.55,
        children: [
          SlidableAction(
            onPressed: (_) {
              controller.togglePin(conv.id);
            },
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            icon: conv.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: conv.isPinned ? '取消置顶'.tr : '置顶'.tr,
            spacing: 4,
          ),
          SlidableAction(
            onPressed: (_) {
              controller.markAsUnread(conv.id);
            },
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            icon: Icons.mark_email_unread_outlined,
            label: '标记未读'.tr,
            spacing: 4,
          ),
          SlidableAction(
            onPressed: (_) {
              _confirmDelete(conv);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '删除'.tr,
            spacing: 4,
          ),
        ],
      ),
      child: Material(
        color: conv.isPinned ? accentColor.withOpacity(0.05) : cardColor,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: conv.avatar != null && conv.avatar!.isNotEmpty
                    ? NetworkImage(conv.avatar!)
                    : null,
                child: (conv.avatar == null || conv.avatar!.isEmpty)
                    ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                    : null,
              ),
              if (conv.isPinned)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                    child: const Icon(Icons.push_pin, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (conv.isMuted)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.volume_off, size: 14, color: subTextColor),
                ),
            ],
          ),
          subtitle: conv.lastMessage != null
              ? Text(
                  _formatLastMessage(conv.lastMessage!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subTextColor, fontSize: 13),
                )
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (conv.lastMessage?.createdAt != null)
                Text(_formatTime(conv.lastMessage!.createdAt!), style: TextStyle(color: subTextColor, fontSize: 12)),
              if (conv.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: Text('${conv.unreadCount > 99 ? '99+' : conv.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
            ],
          ),
          onTap: conv.id.isNotEmpty
              ? () => Get.toNamed('${AppRoutes.chatDetail}/${conv.id}', arguments: {
                  'name': conv.name ?? 'unknown_conversation'.tr,
                  'avatar': conv.avatar ?? '',
                })
              : null,
        ),
      ),
    );
  }

  void _confirmDelete(ConversationModel conv) {
    Get.defaultDialog(
      title: '删除会话'.tr,
      middleText: '确定要删除该会话吗？'.tr,
      textConfirm: '确定'.tr,
      textCancel: '取消'.tr,
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.deleteConversation(conv.id);
      },
    );
  }

  String _formatLastMessage(LastMessage msg) {
    if (msg.type == 'TRANSFER') {
      try {
        String raw = msg.content ?? '';
        if (raw.startsWith('"') && raw.endsWith('"')) {
          raw = jsonDecode(raw) as String;
        }
        if (raw.startsWith('{')) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0).toString();
          final status = (data['status'] ?? 'PENDING').toString();
          final displayAmount = double.tryParse(amount)?.toStringAsFixed(2) ?? amount;
          if (status == 'ACCEPTED') return '[转账] ¥$displayAmount 已收款';
          if (status == 'REFUNDED' || status == 'EXPIRED') return '[转账] ¥$displayAmount 已退回';
          return '[转账] ¥$displayAmount';
        }
      } catch (_) {}
      return '[转账]';
    }
    if (msg.type == 'VOICE') return '[语音]';
    if (msg.type == 'CALL') {
      try {
        String raw = msg.content ?? '';
        if (raw.startsWith('"') && raw.endsWith('"')) {
          raw = jsonDecode(raw) as String;
        }
        if (raw.startsWith('{')) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final callType = data['callType'] == 'VIDEO' ? '视频通话' : '语音通话';
          final status = data['status'] ?? 'ENDED';
          final duration = data['duration'] ?? 0;
          if (status == 'REJECTED') return '[$callType] 已拒绝';
          if (status == 'TIMEOUT' || status == 'MISSED') return '[$callType] 未接听';
          if (duration > 0) {
            final min = duration ~/ 60;
            final sec = duration % 60;
            return '[$callType] ${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
          }
          return '[$callType]';
        }
      } catch (_) {}
      return '[通话]';
    }
    return msg.content ?? '';
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just_now'.tr;
    if (diff.inHours < 1) return '${diff.inMinutes}${'minutes_ago'.tr}';
    if (dt.day == now.day) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (dt.year == now.year) return '${dt.month}/${dt.day}';
    return '${dt.month}/${dt.day}';
  }
}
