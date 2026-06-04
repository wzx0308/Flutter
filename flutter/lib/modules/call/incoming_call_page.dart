import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'call_controller.dart';

class IncomingCallPage extends GetView<CallController> {
  const IncomingCallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = Get.isDarkMode ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 来电标识
              Text(
                controller.isVideo.value ? '视频来电' : '语音来电',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              // 对方头像
              Obx(() => CircleAvatar(
                radius: 60,
                backgroundColor: accentColor.withValues(alpha: 0.2),
                backgroundImage: controller.remoteUserAvatar.value.isNotEmpty
                    ? NetworkImage(controller.remoteUserAvatar.value)
                    : null,
                child: controller.remoteUserAvatar.value.isEmpty
                    ? Icon(Icons.person, size: 60, color: accentColor)
                    : null,
              )),
              const SizedBox(height: 24),
              // 对方昵称
              Obx(() => Text(
                controller.remoteUserName.value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
              )),
              const SizedBox(height: 80),
              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 拒绝按钮
                  Column(
                    children: [
                      GestureDetector(
                        onTap: controller.rejectCall,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('拒绝', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(width: 80),
                  // 接听按钮
                  Column(
                    children: [
                      GestureDetector(
                        onTap: controller.acceptCall,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          child: const Icon(Icons.call, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('接听', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
