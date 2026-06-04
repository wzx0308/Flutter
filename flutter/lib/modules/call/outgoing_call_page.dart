import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'call_controller.dart';

class OutgoingCallPage extends GetView<CallController> {
  const OutgoingCallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = Get.isDarkMode ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 12),
              // 呼叫类型
              Obx(() => Text(
                controller.isVideo.value ? '视频通话' : '语音通话',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              )),
              const SizedBox(height: 16),
              // 呼叫状态动画
              const _PulsingDot(),
              const SizedBox(height: 80),
              // 挂断按钮
              GestureDetector(
                onTap: controller.hangup,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              const Text('点击挂断', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: 0.5 + _controller.value * 0.5,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: Colors.green),
            SizedBox(width: 6),
            Icon(Icons.circle, size: 8, color: Colors.green),
            SizedBox(width: 6),
            Icon(Icons.circle, size: 8, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
