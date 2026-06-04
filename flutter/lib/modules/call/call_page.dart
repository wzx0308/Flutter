import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'call_controller.dart';
import '../../core/services/rtc_service.dart';

class CallPage extends GetView<CallController> {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFF1A1A2E);
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() => controller.isVideo.value
          ? _buildVideoCall(bgColor, accentColor)
          : _buildVoiceCall(bgColor, accentColor)),
    );
  }

  Widget _buildVoiceCall(Color bgColor, Color accentColor) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
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
          // 通话状态
          Obx(() => Text(
            controller.formattedDuration.isNotEmpty ? controller.formattedDuration : '通话中...',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          )),
          const Spacer(),
          // 功能按钮
          _buildActionButtons(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildVideoCall(Color bgColor, Color accentColor) {
    return Stack(
      children: [
        // 远端视频（全屏）
        Obx(() => RtcService.to.remoteUid.value != 0 && RtcService.to.engine != null
            ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: RtcService.to.engine!,
                  canvas: VideoCanvas(uid: RtcService.to.remoteUid.value),
                  connection: RtcConnection(channelId: controller.channelName),
                ),
              )
            : Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: accentColor.withValues(alpha: 0.2),
                  backgroundImage: controller.remoteUserAvatar.value.isNotEmpty
                      ? NetworkImage(controller.remoteUserAvatar.value)
                      : null,
                  child: controller.remoteUserAvatar.value.isEmpty
                      ? Icon(Icons.person, size: 60, color: accentColor)
                      : null,
                ),
              )),
        // 本地小窗（右上角）
        if (RtcService.to.engine != null)
          Positioned(
            top: MediaQuery.of(Get.context!).padding.top + 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 120,
                height: 160,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: RtcService.to.engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),
          ),
        // 顶部信息
        Positioned(
          top: MediaQuery.of(Get.context!).padding.top + 16,
          left: 16,
          child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.remoteUserName.value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              Obx(() => Text(
                controller.formattedDuration.isNotEmpty ? controller.formattedDuration : '',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              )),
            ],
          )),
        ),
        // 底部按钮
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: _buildActionButtons(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircleButton(
          icon: RtcService.to.isMuted.value ? Icons.mic_off : Icons.mic,
          label: '静音',
          onTap: controller.toggleMute,
        ),
        if (controller.isVideo.value)
          _buildCircleButton(
            icon: RtcService.to.isCameraOff.value ? Icons.videocam_off : Icons.videocam,
            label: '摄像头',
            onTap: controller.toggleCamera,
          ),
        if (controller.isVideo.value)
          _buildCircleButton(
            icon: Icons.cameraswitch,
            label: '翻转',
            onTap: controller.switchCamera,
          ),
        _buildCircleButton(
          icon: RtcService.to.isSpeakerOn.value ? Icons.volume_up : Icons.volume_down,
          label: '扬声器',
          onTap: controller.toggleSpeaker,
        ),
        // 挂断按钮
        GestureDetector(
          onTap: controller.hangup,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.call_end, color: Colors.white, size: 30),
          ),
        ),
      ],
    ));
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
