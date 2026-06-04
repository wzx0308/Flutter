import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'ai_chat_list_controller.dart';

class AiChatListPage extends GetView<AiChatListController> {
  const AiChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 每次 build 时刷新列表（从详情页返回时会触发 rebuild）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 延迟刷新，确保存储已写入完成
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          controller.refreshConversations();
        }
      });
    });
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('AI 助手'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF212121),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment_outlined, color: accentColor),
            onPressed: () => controller.createConversation(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.6)],
                    ),
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text('暂无对话'.tr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                Text('点击右上角开始新对话'.tr, style: TextStyle(fontSize: 14, color: subTextColor)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: controller.conversations.length,
          itemBuilder: (_, i) {
            final conv = controller.conversations[i];
            return _buildSlidableItem(conv, cardColor, textColor, subTextColor, accentColor);
          },
        );
      }),
    );
  }

  Widget _buildSlidableItem(
      dynamic conv, Color cardColor, Color textColor, Color subTextColor, Color accentColor) {
    final timeStr = _formatTime(conv.updatedAt);

    return Slidable(
      key: ValueKey(conv.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: (_) => controller.togglePin(conv.id),
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            icon: conv.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: conv.isPinned ? '取消置顶'.tr : '置顶'.tr,
            spacing: 0,
          ),
          SlidableAction(
            onPressed: (_) => _showRenameDialog(conv.id, conv.title, accentColor),
            backgroundColor: const Color(0xFF5C6BC0),
            foregroundColor: Colors.white,
            icon: Icons.edit_outlined,
            label: '重命名'.tr,
            spacing: 0,
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(conv.id),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '删除'.tr,
            spacing: 0,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.6)],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.smart_toy, color: Colors.white, size: 22),
              if (conv.isDeepThinking)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.psychology, color: Colors.amber, size: 14),
                ),
            ],
          ),
        ),
        title: Row(
          children: [
            if (conv.isPinned) ...[
              Icon(Icons.push_pin, size: 14, color: accentColor),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                conv.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${conv.messageCount} 条消息',
          style: TextStyle(fontSize: 13, color: subTextColor),
        ),
        trailing: Text(timeStr, style: TextStyle(fontSize: 12, color: subTextColor)),
        onTap: () => Get.toNamed('/ai-chat/detail/${conv.id}'),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  void _showRenameDialog(String id, String currentTitle, Color accentColor) {
    final ctrl = TextEditingController(text: currentTitle);
    Get.dialog(
      AlertDialog(
        title: Text('重命名'.tr),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: '输入新名称'.tr),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('取消'.tr)),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                controller.renameConversation(id, ctrl.text.trim());
              }
              Get.back();
            },
            child: Text('确定'.tr, style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    Get.dialog(
      AlertDialog(
        title: Text('删除对话'.tr),
        content: Text('确定要删除这个对话吗？'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('取消'.tr)),
          TextButton(
            onPressed: () {
              controller.deleteConversation(id);
              Get.back();
            },
            child: Text('删除'.tr, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
