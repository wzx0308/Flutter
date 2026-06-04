import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'ai_chat_detail_controller.dart';

class AiChatDetailPage extends GetView<AiChatDetailController> {
  const AiChatDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);
    final fillColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await controller.persistBeforeClose();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
        title: Obx(() => Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.6)])),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.conversationTitle.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      Text(controller.isDeepThinking.value ? '深度思考已开启'.tr : 'mimo-v2.5-pro', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ],
            )),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF212121),
        elevation: 0,
        actions: [
          Obx(() => IconButton(
                icon: Icon(Icons.psychology, color: controller.isDeepThinking.value ? Colors.amber : Colors.grey),
                tooltip: controller.isDeepThinking.value ? '关闭深度思考'.tr : '开启深度思考'.tr,
                onPressed: () => controller.toggleDeepThinking(),
              )),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) return _buildEmptyState(accentColor, textColor, subTextColor);
              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (_, i) {
                  final msg = controller.messages[i];
                  final isUser = msg.role == 'user';
                  return _buildMessage(msg, isUser, textColor, accentColor, cardColor);
                },
              );
            }),
          ),
          _buildInputBar(isDark, subTextColor, accentColor, fillColor, context),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor, Color textColor, Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.6)])),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text('你好！我是 AI 助手'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 8),
          Text('可以发图片给我识别，也可以用语音输入'.tr, style: TextStyle(fontSize: 14, color: subTextColor)),
        ],
      ),
    );
  }

  Widget _buildMessage(dynamic msg, bool isUser, Color textColor, Color accentColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.6)])),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? accentColor : cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4), bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片展示
                  if (msg.images != null && msg.images.isNotEmpty)
                    _buildMessageImages(msg.images, isUser),
                  // 文字内容
                  if (msg.content.isNotEmpty || msg.isStreaming)
                    Text(
                      msg.content.isEmpty && msg.isStreaming ? '思考中...' : msg.content,
                      style: TextStyle(color: isUser ? Colors.white : textColor, fontSize: 15, height: 1.5),
                    ),
                  if (msg.isStreaming) ...[
                    const SizedBox(height: 4),
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageImages(List<String> images, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: images.map((img) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: img.startsWith('data:')
                ? Image.memory(base64Decode(img.split(',')[1]), width: 120.w, height: 120.w, fit: BoxFit.cover)
                : Image.network(img, width: 120.w, height: 120.w, fit: BoxFit.cover),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar(bool isDark, Color subTextColor, Color accentColor, Color fillColor, BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE0E0E0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 已选图片预览
          Obx(() {
            if (controller.selectedImages.isEmpty) return const SizedBox.shrink();
            return Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(controller.selectedImages[i].split(',')[1]),
                          width: 72.w, height: 72.w, fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => controller.removeImage(i),
                          child: Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
          // RAG 文档 chips
          _buildDocumentChips(accentColor),
          // 录音中提示
          Obx(() {
            if (!controller.isRecording.value && !controller.isTranscribing.value) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: controller.isRecording.value ? Colors.red.withValues(alpha: 0.1) : accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (controller.isRecording.value) ...[
                    const Icon(Icons.mic, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    const Text('正在录音...', style: TextStyle(color: Colors.red, fontSize: 13)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => controller.stopRecordingAndTranscribe(),
                      child: const Text('停止并识别', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.cancelRecording(),
                      child: const Text('取消', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  ],
                  if (controller.isTranscribing.value) ...[
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    const Text('正在识别语音...', style: TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            );
          }),
          // 输入行
          Row(
            children: [
              // "+" 展开按钮
              GestureDetector(
                onTap: controller.toggleMorePanel,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: controller.showMorePanel.value ? accentColor.withValues(alpha: 0.15) : fillColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    controller.showMorePanel.value ? Icons.close : Icons.add_circle_outline,
                    color: controller.showMorePanel.value ? accentColor : Colors.grey,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 输入框
              Expanded(
                child: TextField(
                  controller: controller.inputCtrl,
                  decoration: InputDecoration(
                    hintText: '输入消息或语音转文字...'.tr,
                    hintStyle: TextStyle(color: subTextColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: fillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) => _send(text),
                  onChanged: (_) => controller.hasTextInput.value = controller.inputCtrl.text.isNotEmpty,
                ),
              ),
              const SizedBox(width: 8),
              // 麦克风 / 发送 / 停止 按钮
              Obx(() {
                final streaming = controller.isStreaming.value;
                final loading = controller.isLoading.value;
                final hasText = controller.hasTextInput.value;
                final recording = controller.isRecording.value;

                // 有文字或正在流式输出 → 显示发送/停止
                if (hasText || streaming || loading) {
                  return GestureDetector(
                    onTap: streaming ? () => controller.cancelStream() : () => _send(null),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: streaming ? Colors.redAccent : accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(streaming ? Icons.stop : Icons.send, color: Colors.white, size: 20),
                    ),
                  );
                }
                // 否则显示麦克风
                return GestureDetector(
                  onLongPressStart: recording ? null : (_) => controller.startRecording(),
                  onLongPressEnd: (_) => controller.stopRecordingAndTranscribe(),
                  onLongPressCancel: () => controller.cancelRecording(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: recording ? Colors.red.withValues(alpha: 0.15) : fillColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.mic, color: recording ? Colors.red : Colors.grey, size: 22),
                  ),
                );
              }),
            ],
          ),
          // 展开面板
          Obx(() {
            if (!controller.showMorePanel.value) return const SizedBox.shrink();
            return _buildMorePanel(isDark, accentColor, context);
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentChips(Color accentColor) {
    return Obx(() {
      if (controller.selectedDocuments.isEmpty && !controller.isUploadingDocument.value) {
        return const SizedBox.shrink();
      }
      return Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // 上传中指示器
            if (controller.isUploadingDocument.value)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 6),
                    Text('上传中...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            // 文档 chips
            ...List.generate(controller.selectedDocuments.length, (i) {
              final doc = controller.selectedDocuments[i];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconForMime(doc.mimeType), size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        doc.originalName,
                        style: TextStyle(fontSize: 12, color: accentColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => controller.removeDocument(i),
                      child: Icon(Icons.close, size: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildMorePanel(bool isDark, Color accentColor, BuildContext context) {
    final bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]!;
    final items = [
      {'icon': Icons.photo_library, 'label': '相册', 'onTap': () { controller.toggleMorePanel(); _showImagePicker(context); }},
      {'icon': Icons.description, 'label': '文件', 'onTap': () { controller.toggleMorePanel(); controller.pickDocument(); }},
      {'icon': Icons.psychology, 'label': '深度思考', 'onTap': () { controller.toggleMorePanel(); controller.toggleDeepThinking(); }},
    ];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ScreenUtil().screenWidth > 600 ? 5 : 4, mainAxisSpacing: 12.w, crossAxisSpacing: 12.w,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final icon = item['icon'] as IconData;
          final label = item['label'] as String;
          final onTap = item['onTap'] as VoidCallback;
          return GestureDetector(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 24, color: accentColor),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconForMime(String mimeType) {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.article;
    return Icons.text_snippet;
  }

  void _showImagePicker(BuildContext context) {
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
            const Text('选择图片', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imagePickerOption(Icons.camera_alt, '拍照', () {
                  Get.back();
                  controller.pickImage(ImageSource.camera);
                }),
                _imagePickerOption(Icons.photo_library, '相册', () {
                  Get.back();
                  controller.pickImage(ImageSource.gallery);
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _imagePickerOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, size: 28, color: const Color(0xFF2D2B55)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _send(String? text) {
    final msg = text ?? controller.inputCtrl.text;
    if (msg.trim().isEmpty && controller.selectedImages.isEmpty) return;
    controller.inputCtrl.clear();
    controller.sendMessage(msg, images: controller.selectedImages.toList());
  }
}
