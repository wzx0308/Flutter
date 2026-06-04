import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/upload_service.dart';
import '../../core/services/image_cache_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/web/web_helper.dart';
import '../../data/models/ai_message_model.dart';
import '../../data/models/rag_document_model.dart';
import '../../data/providers/ai_chat_provider.dart';

class AiChatDetailController extends GetxController {
  final messages = <AiMessageModel>[].obs;
  final isLoading = false.obs;
  final isStreaming = false.obs;
  final isDeepThinking = false.obs;
  final conversationTitle = ''.obs;
  bool _isPersisting = false;

  // Expandable panel
  final showMorePanel = false.obs;

  // RAG documents
  final selectedDocuments = <RagDocumentModel>[].obs;
  final isUploadingDocument = false.obs;

  // Input text reactivity
  final hasTextInput = false.obs;

  // Image picker
  final selectedImages = <String>[].obs; // base64 data URIs for preview
  final _imagePicker = ImagePicker();

  // Voice recording
  final isRecording = false.obs;
  final isTranscribing = false.obs;
  Timer? _recordingTimer;
  final AudioRecorder _recorder = AudioRecorder();

  late String conversationId;
  final AiChatProvider _provider = AiChatProvider();
  final UploadService _uploadService = UploadService();
  CancelToken? _currentCancelToken;
  final ScrollController scrollController = ScrollController();
  final inputCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    conversationId = Get.parameters['id'] ?? '';
    _loadMessages();
    _loadConversationMeta();
    _loadDocuments();
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
  }

  @override
  Future<void> onClose() async {
    _currentCancelToken?.cancel();
    _recordingTimer?.cancel();
    _recorder.stop();
    if (!_isPersisting) {
      await _persistMessages();
    }
    scrollController.dispose();
    inputCtrl.dispose();
    super.onClose();
  }

  void _loadMessages() {
    try {
      final list = StorageService.to.getAiMessages(conversationId);
      final parsed = <AiMessageModel>[];
      for (final json in list) {
        try {
          parsed.add(AiMessageModel.fromJson(json));
        } catch (_) {
          // Skip malformed messages instead of failing the entire list
        }
      }
      messages.value = parsed;
    } catch (_) {
      messages.value = [];
    }
  }

  void _loadConversationMeta() {
    final convs = StorageService.to.getAiConversations();
    for (final json in convs) {
      if (json['id'] == conversationId) {
        conversationTitle.value = json['title'] ?? '新对话';
        isDeepThinking.value = json['isDeepThinking'] ?? false;
        break;
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  // ══════════════════════════════════════
  //  Expandable Panel & RAG Documents
  // ══════════════════════════════════════

  void toggleMorePanel() => showMorePanel.value = !showMorePanel.value;

  void _loadDocuments() async {
    try {
      final docs = await _provider.listDocuments(conversationId: conversationId);
      selectedDocuments.value = docs.where((d) => d.isIndexed).toList();
    } catch (_) {}
  }

  Future<void> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt', 'md'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > 50 * 1024 * 1024) {
        Get.snackbar('提示', '文件大小不能超过 50MB');
        return;
      }
      if (file.path == null) {
        Get.snackbar('错误', '无法读取文件');
        return;
      }

      isUploadingDocument.value = true;
      try {
        final doc = await _provider.uploadDocument(
          File(file.path!),
          conversationId: conversationId,
        );
        selectedDocuments.add(doc);
        Get.snackbar('成功', '${doc.originalName} 已上传，正在索引...');
        _pollDocumentStatus(doc.id);
      } catch (e) {
        Get.snackbar('错误', '文档上传失败: $e');
      } finally {
        isUploadingDocument.value = false;
      }
    } catch (e) {
      Get.snackbar('错误', '选择文件失败');
    }
  }

  void _pollDocumentStatus(String docId) async {
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final docs = await _provider.listDocuments(conversationId: conversationId);
        RagDocumentModel? doc;
        for (final d in docs) {
          if (d.id == docId) { doc = d; break; }
        }
        if (doc != null && doc.isIndexed) {
          // 替换为最新的 indexed 版本
          final idx = selectedDocuments.indexWhere((d) => d.id == docId);
          if (idx >= 0) selectedDocuments[idx] = doc;
          Get.snackbar('完成', '文档索引完成，可以开始提问了');
          return;
        }
        if (doc != null && doc.isError) {
          Get.snackbar('错误', '索引失败: ${doc.errorMessage ?? "未知错误"}');
          return;
        }
      } catch (_) {}
    }
  }

  void removeDocument(int index) {
    final doc = selectedDocuments[index];
    selectedDocuments.removeAt(index);
    _provider.deleteDocument(doc.id).catchError((_) {});
  }

  // ══════════════════════════════════════
  //  Image Picker
  // ══════════════════════════════════════

  Future<void> pickImage(ImageSource source) async {
    if (selectedImages.length >= 4) {
      Get.snackbar('提示', '最多选择4张图片');
      return;
    }
    try {
      final file = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64Data = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        selectedImages.add(base64Data);
      }
    } catch (e) {
      Get.snackbar('错误', '选择图片失败');
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  // ══════════════════════════════════════
  //  Voice Recording (Speech-to-Text)
  // ══════════════════════════════════════

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      Get.snackbar('提示', '需要麦克风权限');
      return;
    }
    if (kIsWeb) {
      await _recorder.start(const RecordConfig(), path: '');
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/ai_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        path: path,
      );
    }
    isRecording.value = true;

    // 最长 60 秒自动停止
    _recordingTimer = Timer(const Duration(seconds: 60), () => stopRecordingAndTranscribe());
  }

  Future<void> stopRecordingAndTranscribe() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    isRecording.value = false;

    if (path == null) return;

    isTranscribing.value = true;
    try {
      final Uint8List bytes;
      String fileName;
      String mimeType;
      if (kIsWeb) {
        bytes = await readBlobUrl(path);
        // Web端 MediaRecorder 默认输出 webm 格式
        fileName = 'voice.webm';
        mimeType = 'audio/webm';
      } else {
        bytes = await File(path).readAsBytes();
        fileName = 'voice.wav';
        mimeType = 'audio/wav';
      }
      final text = await _provider.speechToText(bytes, fileName, mimeType);
      if (text.isNotEmpty) {
        inputCtrl.text = text;
        inputCtrl.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
      } else {
        Get.snackbar('提示', '未能识别语音内容');
      }
    } catch (e) {
      Get.snackbar('错误', '语音识别失败: ${e.toString()}');
    } finally {
      isTranscribing.value = false;
      if (!kIsWeb) {
        try { await File(path).delete(); } catch (_) {}
      }
    }
  }

  void cancelRecording() {
    _recordingTimer?.cancel();
    _recorder.stop();
    isRecording.value = false;
  }

  // ══════════════════════════════════════
  //  Send Message
  // ══════════════════════════════════════

  Future<void> sendMessage(String text, {List<String>? images}) async {
    if (text.trim().isEmpty && (images == null || images.isEmpty)) return;
    if (isStreaming.value) return;

    final userImages = images ?? selectedImages.toList();
    selectedImages.clear();

    // 1. 添加用户消息
    final userMsg = AiMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      role: 'user',
      content: text.trim(),
      images: userImages,
      createdAt: DateTime.now(),
    );
    messages.add(userMsg);

    // 2. 添加占位助手消息
    final assistantMsg = AiMessageModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_ai',
      conversationId: conversationId,
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    );
    messages.add(assistantMsg);

    isLoading.value = true;
    _currentCancelToken = CancelToken();
    scrollToBottom();

    try {
      // 3. 构建多模态消息历史
      final apiMessages = <Map<String, dynamic>>[];
      for (final m in messages) {
        if (m.id == assistantMsg.id) continue;
        if (m.images.isNotEmpty) {
          // 多模态内容: [text + image_url]
          final content = <Map<String, dynamic>>[];
          if (m.content.isNotEmpty) {
            content.add({'type': 'text', 'text': m.content});
          }
          for (final img in m.images) {
            content.add({'type': 'image_url', 'image_url': {'url': img}});
          }
          apiMessages.add({'role': m.role, 'content': content});
        } else {
          apiMessages.add({'role': m.role, 'content': m.content});
        }
      }

      // 4. 非流式请求（通过后端代理）
      final reply = await _provider.chatCompletion(
        messages: apiMessages,
        model: AppConstants.aiModel,
        deepThinking: isDeepThinking.value,
        mode: selectedDocuments.isNotEmpty ? 'rag' : null,
        conversationId: conversationId,
      );

      isLoading.value = false;

      final idx = messages.indexWhere((m) => m.id == assistantMsg.id);
      if (idx >= 0) {
        assistantMsg.content = reply;
        assistantMsg.isStreaming = false;
        messages.refresh();
        scrollToBottom();
      }
    } on DioException catch (e) {
      final idx = messages.indexWhere((m) => m.id == assistantMsg.id);
      if (idx >= 0) {
        if (e.type == DioExceptionType.cancel) {
          assistantMsg.content += assistantMsg.content.isEmpty ? '[已取消]' : '';
        } else {
          assistantMsg.content = assistantMsg.content.isEmpty
              ? '网络错误，请稍后重试。'
              : assistantMsg.content;
        }
        assistantMsg.isStreaming = false;
        messages.refresh();
      }
    } catch (e) {
      final idx = messages.indexWhere((m) => m.id == assistantMsg.id);
      if (idx >= 0) {
        assistantMsg.content = '抱歉，发生了未知错误。';
        assistantMsg.isStreaming = false;
        messages.refresh();
      }
    } finally {
      isStreaming.value = false;
      isLoading.value = false;
      _currentCancelToken = null;
      _persistMessages();
      _updateConversationMeta(text);
    }
  }

  void cancelStream() {
    _currentCancelToken?.cancel();
  }

  void toggleDeepThinking() {
    isDeepThinking.value = !isDeepThinking.value;
    _persistConversationMeta();
  }

  Future<void> _persistMessages() async {
    _isPersisting = true;
    try {
      // Save images to filesystem, keep only file paths in GetStorage
      final imageCache = ImageCacheService.to;
      final jsonList = <Map<String, dynamic>>[];
      for (final m in messages) {
        final savedPaths = <String>[];
        for (final img in m.images) {
          if (ImageCacheService.isFilePath(img)) {
            savedPaths.add(img);
          } else {
            final path = await imageCache.saveImage(img);
            savedPaths.add(path ?? img);
          }
        }
        final json = m.toJson();
        json['images'] = savedPaths;
        jsonList.add(json);
      }
      // Safety: skip persisting if data exceeds a reasonable size (~500KB)
      final encoded = jsonEncode(jsonList);
      if (encoded.length > 500 * 1024) {
        // Keep only the last 20 messages to stay within safe storage limits
        final trimmed = jsonList.length > 20 ? jsonList.sublist(jsonList.length - 20) : jsonList;
        await StorageService.to.saveAiMessages(conversationId, trimmed);
      } else {
        await StorageService.to.saveAiMessages(conversationId, jsonList);
      }
    } finally {
      _isPersisting = false;
    }
  }

  /// 退出前确保数据已持久化
  Future<void> persistBeforeClose() async {
    if (_isPersisting) return;
    await _persistMessages();
    String firstUserContent = '';
    for (final m in messages) {
      if (m.role == 'user') {
        firstUserContent = m.content;
        break;
      }
    }
    _updateConversationMeta(firstUserContent);
  }

  void _updateConversationMeta(String firstUserMessage) {
    final convs = StorageService.to.getAiConversations();
    bool updated = false;
    for (int i = 0; i < convs.length; i++) {
      if (convs[i]['id'] == conversationId) {
        convs[i]['updatedAt'] = DateTime.now().toIso8601String();
        convs[i]['messageCount'] = messages.length;
        if (convs[i]['title'] == '新对话' && messages.length <= 2) {
          convs[i]['title'] = firstUserMessage.length > 20
              ? '${firstUserMessage.substring(0, 20)}...'
              : firstUserMessage;
          conversationTitle.value = convs[i]['title'];
        }
        updated = true;
        break;
      }
    }
    if (updated) {
      StorageService.to.saveAiConversations(convs);
    }
  }

  void _persistConversationMeta() {
    final convs = StorageService.to.getAiConversations();
    for (int i = 0; i < convs.length; i++) {
      if (convs[i]['id'] == conversationId) {
        convs[i]['isDeepThinking'] = isDeepThinking.value;
        break;
      }
    }
    StorageService.to.saveAiConversations(convs);
  }
}
