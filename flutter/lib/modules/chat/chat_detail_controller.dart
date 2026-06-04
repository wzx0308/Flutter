import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../core/network/socket_service.dart';
import '../../core/web/web_helper.dart';
import '../../core/network/upload_service.dart';
import '../../core/storage/storage_service.dart';
import 'chat_list_controller.dart';
import '../call/call_controller.dart';

class ChatDetailController extends GetxController {
  final ChatRepository _repo = ChatRepository();
  final UploadService _uploadService = UploadService();
  final messageCtrl = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final messages = <MessageModel>[].obs;
  final isLoading = false.obs;
  final isTyping = false.obs;
  final isMutualFollow = true.obs;
  final hasSentFirstMessage = false.obs;
  final showMorePanel = false.obs;

  String conversationId = '';
  String? _myUserId;
  String otherUserId = '';
  String otherUserName = '';
  final otherUserAvatar = ''.obs;

  dynamic Function(dynamic)? _onReceiveMessageCallback;
  dynamic Function(dynamic)? _onTypingCallback;
  dynamic Function(dynamic)? _onRestrictedCallback;
  Timer? _typingTimer;

  // Voice Recording
  final isRecording = false.obs;
  final recordingDuration = 0.obs;
  final isCancelled = false.obs;
  final recordingAmplitude = 0.0.obs;
  Timer? _recordingTimer;
  Timer? _amplitudeTimer;
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  double _startGlobalY = 0;

  // Voice Playback
  final playingMessageId = ''.obs;
  final playbackDuration = 0.obs;
  final isPlaying = false.obs;
  Timer? _playbackTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Route tracking
  Timer? _lastRouteCheckTimer;
  bool _isCurrentRoute = true;

  @override
  void onInit() {
    super.onInit();
    conversationId = Get.parameters['id'] ?? '';
    if (conversationId.isEmpty) {
      Get.back();
      return;
    }
    _myUserId = StorageService.to.getUser()?['id'];
    // 从路由参数立即获取头像，避免异步加载导致的空白
    final args = Get.arguments;
    if (args is Map) {
      otherUserName = args['name'] ?? '';
      otherUserAvatar.value = args['avatar'] ?? '';
    }
    _loadConversation();
    _loadMessages();
    _setupSocket();
    _setupRestrictedListener();
    SocketService.to.markRead(conversationId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ChatListController>()) {
        Get.find<ChatListController>().clearLocalUnread(conversationId);
      }
    });

    // 监听路由变化，从其他页面返回时刷新消息
    _setupRouteListener();

    _audioPlayer.onPlayerComplete.listen((_) {
      isPlaying.value = false;
      playingMessageId.value = '';
      playbackDuration.value = 0;
      _playbackTimer?.cancel();
    });
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    _playbackTimer?.cancel();
    _lastRouteCheckTimer?.cancel();
    _recorder.stop();
    _audioPlayer.dispose();
    messageCtrl.dispose();
    scrollController.dispose();
    if (_onReceiveMessageCallback != null) SocketService.to.off('chat:receive', _onReceiveMessageCallback);
    if (_onTypingCallback != null) SocketService.to.off('chat:typing', _onTypingCallback);
    if (_onRestrictedCallback != null) SocketService.to.off('chat:restricted', _onRestrictedCallback);
    super.onClose();
  }

  Future<void> _loadConversation() async {
    try {
      final conv = await _repo.getConversation(conversationId);
      isMutualFollow.value = conv.isMutualFollow;
      if (conv.members != null) {
        for (final m in conv.members!) {
          if (m['id'] != _myUserId) {
            otherUserId = m['id'] ?? '';
            otherUserName = m['nickname'] ?? m['username'] ?? '';
            otherUserAvatar.value = m['avatar'] ?? '';
            break;
          }
        }
      }
    } catch (_) {}
  }

  void _setupRestrictedListener() {
    _onRestrictedCallback = (data) {
      hasSentFirstMessage.value = true;
      if (data is Map && data['message'] != null) {
        Get.snackbar('', data['message'], snackPosition: SnackPosition.BOTTOM);
      }
    };
    SocketService.to.onRestricted(_onRestrictedCallback!);
  }

  Future<void> _loadMessages() async {
    isLoading.value = true;
    try {
      final list = await _repo.getMessages(conversationId);
      messages.value = list;
      if (!isMutualFollow.value && list.isNotEmpty) hasSentFirstMessage.value = true;
      scrollToBottom();
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  void _setupSocket() {
    _onReceiveMessageCallback = (data) {
      if (data['conversationId'] == conversationId) {
        final msg = MessageModel.fromJson(data);
        // 去重：如果消息已存在（通过ID匹配），跳过
        final exists = messages.any((m) => m.id == msg.id && m.id.isNotEmpty);
        if (exists) return;

        if (msg.senderId == _myUserId) {
          final idx = messages.lastIndexWhere((m) => m.status == 'pending' && m.content == msg.content);
          if (idx >= 0) {
            messages[idx] = msg;
          } else {
            messages.add(msg);
          }
        } else {
          messages.add(msg);
          SocketService.to.markRead(conversationId);
          if (Get.isRegistered<ChatListController>()) {
            Get.find<ChatListController>().clearLocalUnread(conversationId);
          }
        }
      }
    };
    SocketService.to.onReceiveMessage(_onReceiveMessageCallback!);

    _onTypingCallback = (data) {
      if (data['conversationId'] == conversationId) {
        isTyping.value = true;
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () => isTyping.value = false);
      }
    };
    SocketService.to.onTyping(_onTypingCallback!);
  }

  void sendMessage() {
    final text = messageCtrl.text.trim();
    if (text.isEmpty) return;
    if (!isMutualFollow.value && hasSentFirstMessage.value) return;
    SocketService.to.sendMessage(conversationId, text);
    messages.add(MessageModel(
      id: '', conversationId: conversationId, senderId: _myUserId,
      content: text, type: 'TEXT', createdAt: DateTime.now().toIso8601String(), status: 'pending',
    ));
    if (!isMutualFollow.value) hasSentFirstMessage.value = true;
    messageCtrl.clear();
  }

  void sendTyping() => SocketService.to.sendTyping(conversationId);

  bool isMe(String? senderId) => senderId == _myUserId;

  void toggleMorePanel() => showMorePanel.value = !showMorePanel.value;

  void startVoiceCall() {
    if (otherUserId.isEmpty) return;
    if (!Get.isRegistered<CallController>()) {
      Get.put(CallController());
    }
    Get.find<CallController>().startCall(
      otherUserId,
      video: false,
      conversationId: conversationId,
      arguments: {'name': otherUserName, 'avatar': otherUserAvatar.value},
    );
  }

  void startVideoCall() {
    if (otherUserId.isEmpty) return;
    if (!Get.isRegistered<CallController>()) {
      Get.put(CallController());
    }
    Get.find<CallController>().startCall(
      otherUserId,
      video: true,
      conversationId: conversationId,
      arguments: {'name': otherUserName, 'avatar': otherUserAvatar.value},
    );
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  void _setupRouteListener() {
    // 使用路由observer检测从其他页面返回
    // 当从转账成功页返回时，重新加载消息
    _lastRouteCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final current = Get.currentRoute;
      if (current.contains('/chat/detail') && !_isCurrentRoute) {
        _isCurrentRoute = true;
        _loadMessages();
      } else if (!current.contains('/chat/detail')) {
        _isCurrentRoute = false;
      }
    });
  }

  // ═══════════════ Voice Recording ═══════════════

  Future<void> startRecording([double? globalY]) async {
    if (!await _recorder.hasPermission()) {
      Get.snackbar('', '需要录音权限');
      return;
    }
    _startGlobalY = globalY ?? 0;
    isCancelled.value = false;

    if (kIsWeb) {
      await _recorder.start(const RecordConfig(), path: '');
    } else {
      final dir = await getTemporaryDirectory();
      _currentRecordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );
    }

    isRecording.value = true;
    recordingDuration.value = 0;

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordingDuration.value++;
      if (recordingDuration.value >= 60) {
        stopRecording();
      }
    });

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (await _recorder.isRecording()) {
        final amplitude = await _recorder.getAmplitude();
        recordingAmplitude.value = (amplitude.current.clamp(-160, 0) + 160) / 160;
      }
    });
  }

  void updateSwipePosition(double globalY) {
    isCancelled.value = (_startGlobalY - globalY) > 80;
  }

  Future<void> stopRecording() async {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    recordingAmplitude.value = 0;

    final path = await _recorder.stop();
    isRecording.value = false;

    if (isCancelled.value || recordingDuration.value < 1) {
      if (!kIsWeb && path != null) {
        try { await File(path).delete(); } catch (_) {}
      }
      recordingDuration.value = 0;
      isCancelled.value = false;
      return;
    }

    if (path == null) {
      recordingDuration.value = 0;
      return;
    }

    _sendVoiceMessage(path, recordingDuration.value);
    recordingDuration.value = 0;
  }

  void cancelRecording() {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    recordingAmplitude.value = 0;
    _recorder.stop();
    isRecording.value = false;
    isCancelled.value = false;
    recordingDuration.value = 0;
    if (!kIsWeb && _currentRecordingPath != null) {
      try { File(_currentRecordingPath!).deleteSync(); } catch (_) {}
    }
  }

  Future<void> _sendVoiceMessage(String filePath, int duration) async {
    try {
      final Uint8List bytes;
      if (kIsWeb) {
        bytes = await readBlobUrl(filePath);
      } else {
        final file = File(filePath);
        bytes = await file.readAsBytes();
      }
      final url = await _uploadService.uploadAudioBytes(Uint8List.fromList(bytes), 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
      SocketService.to.sendMessage(conversationId, '${duration}s', type: 'VOICE', mediaUrl: url);
      messages.add(MessageModel(
        id: '', conversationId: conversationId, senderId: _myUserId,
        content: '${duration}s', type: 'VOICE', mediaUrl: url,
        createdAt: DateTime.now().toIso8601String(), status: 'pending',
      ));
    } catch (e) {
      Get.snackbar('', '语音发送失败');
    }
  }

  // ═══════════════ Voice Playback ═══════════════

  Future<void> playVoice(MessageModel msg) async {
    if (msg.mediaUrl == null || msg.mediaUrl!.isEmpty) return;

    if (playingMessageId.value == msg.id && isPlaying.value) {
      await _audioPlayer.pause();
      isPlaying.value = false;
      _playbackTimer?.cancel();
      return;
    }

    if (isPlaying.value) {
      await _audioPlayer.stop();
      _playbackTimer?.cancel();
    }

    playingMessageId.value = msg.id;
    isPlaying.value = true;
    playbackDuration.value = 0;

    final seconds = parseVoiceDuration(msg.content);

    try {
      await _audioPlayer.play(UrlSource(msg.mediaUrl!));
      _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (isPlaying.value) {
          playbackDuration.value++;
          if (seconds > 0 && playbackDuration.value >= seconds) {
            timer.cancel();
          }
        }
      });
    } catch (e) {
      isPlaying.value = false;
      playingMessageId.value = '';
    }
  }

  int parseVoiceDuration(String? content) {
    if (content == null) return 0;
    return int.tryParse(content.replaceAll('s', '')) ?? 0;
  }

  String formatVoiceDuration(int seconds) {
    return '${seconds}\'\'';
  }
}
