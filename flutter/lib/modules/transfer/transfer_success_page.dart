import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransferSuccessPage extends StatelessWidget {
  const TransferSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final amount = Get.arguments?['amount'] ?? 0;
    final receiverName = Get.arguments?['receiverName'] ?? '';
    final receiverAvatar = Get.arguments?['receiverAvatar'] ?? '';
    final conversationId = Get.arguments?['conversationId'] ?? '';
    final isDark = Get.isDarkMode;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                '转账成功',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF212121)),
              ),
              const SizedBox(height: 8),
              Text(
                '¥${(amount as double).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: accentColor),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('已转账给 ', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: accentColor.withValues(alpha: 0.1),
                    backgroundImage: receiverAvatar.toString().isNotEmpty
                        ? NetworkImage(receiverAvatar.toString())
                        : null,
                    child: receiverAvatar.toString().isEmpty
                        ? Icon(Icons.person, size: 14, color: accentColor)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(receiverName.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF212121))),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    if (conversationId.isNotEmpty) {
                      Get.back(); // 返回聊天页
                    } else {
                      Get.offAllNamed('/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  child: const Text('返回聊天', style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
