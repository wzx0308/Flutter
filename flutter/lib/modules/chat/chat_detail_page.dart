import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'chat_detail_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../data/providers/transfer_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/message_model.dart';
import '../wallet/widgets/payment_password_dialog.dart';

class ChatDetailPage extends GetView<ChatDetailController> {
  const ChatDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;
    final fillColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]!;
    final borderColor = isDark ? Colors.grey[700]! : const Color(0xFFE0E0E0);
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    final chatName = Get.arguments?['name'] ?? 'chat'.tr;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (controller.otherUserId.isNotEmpty) {
              Get.toNamed('${AppRoutes.userDetail}/${controller.otherUserId}');
            }
          },
          child: Row(
            children: [
              Obx(() => CircleAvatar(
                radius: 16,
                backgroundColor: accentColor.withValues(alpha: 0.1),
                backgroundImage: controller.otherUserAvatar.value.isNotEmpty ? NetworkImage(controller.otherUserAvatar.value) : null,
                child: controller.otherUserAvatar.value.isEmpty
                    ? Text(chatName[0].toUpperCase(), style: TextStyle(color: accentColor, fontSize: 12))
                    : null,
              )),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chatName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                    Obx(() => controller.isTyping.value
                        ? Text('typing'.tr, style: TextStyle(fontSize: 12, color: subTextColor))
                        : const SizedBox.shrink()),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            onSelected: (v) {
              if (v == 'call') controller.startVoiceCall();
              if (v == 'video') controller.startVideoCall();
              if (v == 'block') Get.snackbar('', '拉黑功能开发中');
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'call', child: Row(children: [const Icon(Icons.call, size: 18), const SizedBox(width: 8), Text('voice_call'.tr)])),
              PopupMenuItem(value: 'video', child: Row(children: [const Icon(Icons.videocam, size: 18), const SizedBox(width: 8), Text('video_call'.tr)])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'block', child: Row(children: [Icon(Icons.block, size: 18, color: Colors.red[400]), const SizedBox(width: 8), Text('block_user'.tr, style: TextStyle(color: Colors.red[400]))])),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildMessageList(isDark, textColor, subTextColor, accentColor)),
              _buildInputBar(context, isDark, fillColor, borderColor, accentColor),
            ],
          ),
          Obx(() => controller.isRecording.value
              ? _buildRecordingOverlay(context, isDark, accentColor)
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildRecordingOverlay(BuildContext context, bool isDark, Color accentColor) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        controller.updateSwipePosition(details.globalPosition.dy);
      },
      onVerticalDragEnd: (_) => controller.stopRecording(),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Obx(() {
            final cancelled = controller.isCancelled.value;
            final duration = controller.recordingDuration.value;
            final amp = controller.recordingAmplitude.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 80,
                  child: CustomPaint(
                    painter: _WavePainter(amplitude: amp, color: cancelled ? Colors.red : Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(duration ~/ 60).toString().padLeft(2, '0')}:${(duration % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(color: cancelled ? Colors.red : Colors.white, fontSize: 36, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 20),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(color: cancelled ? Colors.red : Colors.white70, fontSize: 14),
                  child: Text(cancelled ? '松开取消' : '上滑取消发送'),
                ),
                const SizedBox(height: 12),
                if (duration < 1)
                  const Text('录音至少1秒', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMessageList(bool isDark, Color textColor, Color subTextColor, Color accentColor) {
    return Obx(() {
      if (controller.isLoading.value && controller.messages.isEmpty) {
        return Center(child: CircularProgressIndicator(color: accentColor));
      }
      if (controller.messages.isEmpty) {
        return Center(child: Text('no_conversations'.tr, style: TextStyle(color: subTextColor)));
      }
      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: controller.messages.length,
        itemBuilder: (_, i) {
          final msg = controller.messages[i];
          final isMe = controller.isMe(msg.senderId);
          return _buildMessageBubble(msg, isMe, isDark, accentColor);
        },
      );
    });
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe, bool isDark, Color accentColor) {
    final isVoice = msg.type == 'VOICE';
    final isTransfer = msg.type == 'TRANSFER';
    final isCall = msg.type == 'CALL';
    final timeStr = _formatTime(msg.createdAt);
    // 获取当前用户头像
    final myAvatar = StorageService.to.getUser()?['avatar'] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                GestureDetector(
                  onTap: () {
                    if (controller.otherUserId.isNotEmpty) {
                      Get.toNamed('${AppRoutes.userDetail}/${controller.otherUserId}');
                    }
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: accentColor.withValues(alpha: 0.1),
                    backgroundImage: controller.otherUserAvatar.value.isNotEmpty ? NetworkImage(controller.otherUserAvatar.value) : null,
                    child: controller.otherUserAvatar.value.isEmpty
                        ? Text((msg.senderName ?? 'U')[0].toUpperCase(), style: TextStyle(color: accentColor, fontSize: 13))
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? accentColor : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: isTransfer
                      ? _buildTransferCard(msg, isMe, isDark)
                      : isVoice
                      ? _buildVoiceBubble(msg, isMe, isDark, accentColor)
                      : isCall
                      ? _buildCallBubble(msg, isMe, isDark, accentColor)
                      : Text(
                          msg.content ?? '',
                          style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 15),
                        ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  backgroundImage: myAvatar.isNotEmpty ? NetworkImage(myAvatar) : null,
                  child: myAvatar.isEmpty
                      ? Text('我'[0], style: TextStyle(color: accentColor, fontSize: 13))
                      : null,
                ),
              ],
            ],
          ),
          if (timeStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 40, right: 40),
              child: Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceBubble(dynamic msg, bool isMe, bool isDark, Color accentColor) {
    final duration = controller.parseVoiceDuration(msg.content);
    final msgId = msg.id ?? '';
    final playing = controller.playingMessageId.value == msgId && controller.isPlaying.value;

    return GestureDetector(
      onTap: () => controller.playVoice(msg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: playing
                ? SizedBox(
                    key: ValueKey('anim_$msgId'),
                    width: 18,
                    height: 18,
                    child: Icon(Icons.volume_up, size: 18, color: isMe ? Colors.white : accentColor),
                  )
                : Icon(
                    isMe ? Icons.volume_up : Icons.mic,
                    size: 18,
                    color: isMe ? Colors.white : accentColor,
                    key: ValueKey('idle_$msgId'),
                  ),
          ),
          const SizedBox(width: 8),
          ...List.generate(12, (i) {
            final h = playing
                ? 4.0 + sin((controller.playbackDuration.value * 3 + i * 0.8)) * 8
                : 3.0 + sin(i * 0.5) * 3;
            return Container(
              width: 2,
              height: h.clamp(2.0, 16.0),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: (isMe ? Colors.white : accentColor).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
          const SizedBox(width: 8),
          Text(
            controller.formatVoiceDuration(duration),
            style: TextStyle(
              color: isMe ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallBubble(dynamic msg, bool isMe, bool isDark, Color accentColor) {
    String callType = '语音通话';
    String statusText = '';
    int duration = 0;
    try {
      String raw = msg.content ?? '';
      if (raw.startsWith('"') && raw.endsWith('"')) {
        raw = jsonDecode(raw) as String;
      }
      if (raw.startsWith('{')) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        callType = data['callType'] == 'VIDEO' ? '视频通话' : '语音通话';
        duration = data['duration'] ?? 0;
        statusText = data['status'] ?? 'ENDED';
      }
    } catch (_) {}

    IconData icon;
    String label;
    Color iconColor;

    if (statusText == 'REJECTED') {
      icon = Icons.call_end;
      label = '${isMe ? '' : ''}$callType 已拒绝';
      iconColor = Colors.orange;
    } else if (statusText == 'TIMEOUT' || statusText == 'MISSED') {
      icon = Icons.call_missed;
      label = '${isMe ? '' : ''}$callType 未接听';
      iconColor = Colors.red;
    } else {
      // ENDED or ACCEPTED
      icon = Icons.call;
      final min = duration ~/ 60;
      final sec = duration % 60;
      final durStr = duration > 0 ? ' ${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}' : '';
      label = '$callType$durStr';
      iconColor = isMe ? Colors.white70 : accentColor;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isMe ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (dt.day == now.day) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputBar(BuildContext context, bool isDark, Color fillColor, Color borderColor, Color accentColor) {
    return Obx(() {
      final restricted = !controller.isMutualFollow.value && controller.hasSentFirstMessage.value;
      return Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: restricted
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text('mutual_follow_chat_hint'.tr, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 13)),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: controller.toggleMorePanel,
                        icon: Icon(Icons.add_circle_outline, color: isDark ? Colors.grey[400] : Colors.grey),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller.messageCtrl,
                          decoration: InputDecoration(
                            hintText: 'message_hint'.tr,
                            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: fillColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onChanged: (_) => controller.sendTyping(),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => controller.sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (controller.messageCtrl.text.isEmpty && !controller.isRecording.value)
                        GestureDetector(
                          onLongPressStart: (details) => controller.startRecording(details.globalPosition.dy),
                          onLongPressEnd: (_) => controller.stopRecording(),
                          onLongPressCancel: () => controller.cancelRecording(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                            child: const Icon(Icons.mic, color: Colors.white, size: 20),
                          ),
                        )
                      else if (controller.isRecording.value)
                        GestureDetector(
                          onTap: controller.cancelRecording,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: controller.sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                            child: const Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                  if (controller.showMorePanel.value)
                    _buildMorePanel(isDark, accentColor),
                ],
              ),
      );
    });
  }

  Widget _buildTransferCard(dynamic msg, bool isMe, bool isDark) {
    String amount = '0.00';
    String remark = '';
    String status = 'PENDING';
    String transferId = '';
    try {
      String raw = msg.content ?? '';
      // 处理双重编码：content 可能是 "\"{ ... }\"" 而不是 "{ ... }"
      if (raw.startsWith('"') && raw.endsWith('"')) {
        raw = jsonDecode(raw) as String;
      }
      if (raw.startsWith('{')) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        amount = (data['amount'] ?? 0).toString();
        remark = (data['remark'] ?? '').toString();
        status = (data['status'] ?? 'PENDING').toString();
        transferId = (data['transferId'] ?? '').toString();
      }
    } catch (_) {}

    final isPending = status == 'PENDING';
    final isAccepted = status == 'ACCEPTED';
    final isRefunded = status == 'REFUNDED' || status == 'EXPIRED';

    // 格式化金额显示
    final displayAmount = double.tryParse(amount)?.toStringAsFixed(2) ?? amount;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isRefunded
              ? [Colors.grey[400]!, Colors.grey[500]!]
              : const [Color(0xFFFF9800), Color(0xFFFF6D00)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isRefunded ? Icons.replay : Icons.monetization_on, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                isAccepted
                    ? (isMe ? '已转账' : '已收款')
                    : isRefunded
                        ? '已退回'
                        : (isMe ? '转账' : '收到转账'),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('¥$displayAmount', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          if (remark.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(remark, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
          ],
          const SizedBox(height: 10),
          if (!isMe && isPending)
            SizedBox(
              width: double.infinity, height: 30,
              child: ElevatedButton(
                onPressed: () => _showTransferActions(transferId, amount, msg),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: EdgeInsets.zero),
                child: const Text('确认收款', style: TextStyle(color: Color(0xFFFF6D00), fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            )
          else if (isMe || isAccepted || isRefunded)
            Text(
              isAccepted ? '已收款' : isRefunded ? '已退回' : '待收款',
              style: TextStyle(color: Colors.white.withValues(alpha: isAccepted ? 1.0 : 0.7), fontSize: 12, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  void _showTransferActions(String transferId, String amount, dynamic msg) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('收到转账 ¥$amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Get.isDarkMode ? Colors.white : const Color(0xFF212121))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Get.back();
                  try {
                    final provider = TransferProvider();
                    final res = await provider.acceptTransfer(transferId);
                    if (res['code'] == 0 || res['success'] == true) {
                      _updateTransferStatus(msg, 'ACCEPTED');
                      Get.snackbar('收款成功', '资金已到账');
                    } else {
                      Get.snackbar('收款失败', res['message'] ?? '请稍后重试');
                    }
                  } on DioException catch (e) {
                    final msg = e.response?.data?['message'] ?? e.message ?? '网络错误';
                    Get.snackbar('收款失败', msg);
                  } catch (e) {
                    Get.snackbar('收款失败', '请稍后重试');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('确认收款', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                Get.back();
                try {
                  final provider = TransferProvider();
                  final res = await provider.refundTransfer(transferId);
                  if (res['code'] == 0 || res['success'] == true) {
                    _updateTransferStatus(msg, 'REFUNDED');
                    Get.snackbar('已退回', '转账已退回');
                  } else {
                    Get.snackbar('退回失败', res['message'] ?? '请稍后重试');
                  }
                } on DioException catch (e) {
                  final msg = e.response?.data?['message'] ?? e.message ?? '网络错误';
                  Get.snackbar('退回失败', msg);
                } catch (e) {
                  Get.snackbar('退回失败', '请稍后重试');
                }
              },
              child: const Text('退回', style: TextStyle(color: Colors.grey)),
            ),
            SizedBox(height: MediaQuery.of(Get.context!).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _updateTransferStatus(dynamic msg, String newStatus) {
    try {
      String raw = msg.content ?? '';
      if (raw.startsWith('"') && raw.endsWith('"')) {
        raw = jsonDecode(raw) as String;
      }
      final data = jsonDecode(raw) as Map<String, dynamic>;
      data['status'] = newStatus;
      final newContent = jsonEncode(data);

      // 替换消息对象（而不是修改原对象），确保 Obx 检测到变化
      final idx = controller.messages.indexWhere((m) => m.id == msg.id);
      if (idx >= 0) {
        controller.messages[idx] = MessageModel(
          id: msg.id,
          conversationId: msg.conversationId,
          senderId: msg.senderId,
          type: msg.type,
          content: newContent,
          mediaUrl: msg.mediaUrl,
          status: msg.status,
          senderName: msg.senderName,
          senderAvatar: msg.senderAvatar,
          createdAt: msg.createdAt,
        );
      }
    } catch (_) {}
  }

  void _showTransferSheet(bool isDark, Color accentColor) {
    final amountCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    final isLoading = false.obs;
    final balance = 0.0.obs;

    // 加载余额
    () async {
      try {
        final api = ApiClient();
        final res = await api.dio.get(ApiEndpoints.walletBalance);
        if (res.data['code'] == 0) {
          balance.value = (res.data['data']['balance'] ?? 0).toDouble();
        }
      } catch (_) {}
    }();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            // 收款人
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  backgroundImage: controller.otherUserAvatar.value.isNotEmpty
                      ? NetworkImage(controller.otherUserAvatar.value)
                      : null,
                  child: controller.otherUserAvatar.value.isEmpty
                      ? Icon(Icons.person, color: accentColor, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('转账给', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    Text(controller.otherUserName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF212121))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 金额输入
            Row(
              children: [
                Text('¥', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accentColor)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF212121)),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.grey[300], fontSize: 28),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey[200]),
            Obx(() => Text(
              '余额 ¥${balance.value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            )),
            const SizedBox(height: 16),
            // 备注
            TextField(
              controller: remarkCtrl,
              maxLength: 20,
              decoration: InputDecoration(
                hintText: '转账备注（选填）',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            // 确认按钮
            Obx(() => SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading.value ? null : () async {
                  final amountText = amountCtrl.text.trim();
                  final amount = double.tryParse(amountText);
                  if (amount == null || amount <= 0) {
                    Get.snackbar('提示', '请输入有效金额');
                    return;
                  }
                  if (amount > balance.value) {
                    Get.snackbar('提示', '余额不足');
                    return;
                  }
                  // 检查支付密码
                  try {
                    final api = ApiClient();
                    final statusRes = await api.dio.get(ApiEndpoints.paymentPasswordStatus);
                    final hasPassword = statusRes.data['data']?['hasPassword'] ?? false;
                    if (!hasPassword) {
                      Get.back();
                      Get.defaultDialog(
                        title: '提示',
                        middleText: '请先设置支付密码',
                        textConfirm: '去设置',
                        textCancel: '取消',
                        onConfirm: () { Get.back(); Get.toNamed('/wallet/set-password'); },
                      );
                      return;
                    }
                  } catch (_) {}

                  // 弹出支付密码输入框
                  final password = await showPaymentPasswordDialog();
                  if (password == null) return;

                  isLoading.value = true;
                  try {
                    final provider = TransferProvider();
                    final idempotencyKey = const Uuid().v4();
                    final res = await provider.createTransfer(
                      receiverId: controller.otherUserId,
                      amount: amount,
                      remark: remarkCtrl.text.trim().isNotEmpty ? remarkCtrl.text.trim() : null,
                      paymentPassword: password,
                      idempotencyKey: idempotencyKey,
                    );
                    if (res['code'] == 0) {
                      Get.back();
                      Get.snackbar('转账成功', '已转账 ¥${amount.toStringAsFixed(2)}');
                    } else {
                      Get.snackbar('转账失败', res['message'] ?? '请稍后重试');
                    }
                  } on DioException catch (e) {
                    final msg = e.response?.data?['message'] ?? e.message ?? '网络错误';
                    Get.snackbar('转账失败', msg);
                  } catch (e) {
                    Get.snackbar('转账失败', '网络错误');
                  } finally {
                    isLoading.value = false;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('确认转账', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )),
            SizedBox(height: MediaQuery.of(Get.context!).viewInsets.bottom),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMorePanel(bool isDark, Color accentColor) {
    final items = [
      {'icon': Icons.camera_alt, 'label': '拍照'.tr, 'onTap': () => Get.snackbar('', '拍照功能开发中')},
      {'icon': Icons.photo_library, 'label': '相册'.tr, 'onTap': () => Get.snackbar('', '相册功能开发中')},
      {'icon': Icons.monetization_on, 'label': '转账'.tr, 'onTap': () => _showTransferSheet(isDark, accentColor)},
      {'icon': Icons.card_giftcard, 'label': '红包'.tr, 'onTap': () => Get.snackbar('', '红包功能开发中')},
      {'icon': Icons.location_on, 'label': '位置'.tr, 'onTap': () => Get.snackbar('', '位置功能开发中')},
      {'icon': Icons.call, 'label': '语音通话'.tr, 'onTap': () => controller.startVoiceCall()},
      {'icon': Icons.videocam, 'label': '视频通话'.tr, 'onTap': () => controller.startVideoCall()},
    ];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: ScreenUtil().screenWidth > 600 ? 5 : 4, mainAxisSpacing: 12.w, crossAxisSpacing: 12.w),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: item['onTap'] as VoidCallback,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: isDark ? Colors.grey[700] : Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Icon(item['icon'] as IconData, color: accentColor, size: 24),
                ),
                const SizedBox(height: 4),
                Text(item['label'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double amplitude;
  final Color color;
  _WavePainter({required this.amplitude, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 3..strokeCap = StrokeCap.round;
    final centerY = size.height / 2;
    final totalBars = (size.width / 7).floor();

    for (int i = 0; i < totalBars; i++) {
      final x = i * 7.0 + 3.5;
      final normalizedPos = (i / totalBars) * 2 - 1;
      final wave = sin(normalizedPos * pi * 2 + DateTime.now().millisecondsSinceEpoch * 0.005);
      final barHeight = (10 + wave * amplitude * 25).clamp(4.0, size.height * 0.8);
      canvas.drawLine(Offset(x, centerY - barHeight / 2), Offset(x, centerY + barHeight / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.amplitude != amplitude;
}
