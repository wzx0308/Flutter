import 'dart:async';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/network/socket_service.dart';
import '../../core/services/rtc_service.dart';
import '../../data/providers/call_provider.dart';
import 'call_page.dart';
import 'outgoing_call_page.dart';
import 'incoming_call_page.dart';

enum CallState { idle, ringing, outgoing, inCall }

class CallController extends GetxController {
  final CallProvider _callProvider = CallProvider();
  final callState = CallState.idle.obs;
  final isVideo = false.obs;
  final callDuration = 0.obs;
  final remoteUserName = ''.obs;
  final remoteUserAvatar = ''.obs;

  String? _currentCallId;
  String? _channelName;
  String get channelName => _channelName ?? '';
  Timer? _durationTimer;
  Timer? _ringingTimer;
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..onPlayerComplete.listen((_) {})
    ..onLog.listen((_) {});

  // Socket 回调引用（用于清理）
  dynamic Function(dynamic)? _onCallCreated;
  dynamic Function(dynamic)? _onCallIncoming;
  dynamic Function(dynamic)? _onCallAccepted;
  dynamic Function(dynamic)? _onCallRejected;
  dynamic Function(dynamic)? _onCallEnded;
  dynamic Function(dynamic)? _onCallTimeout;

  @override
  void onInit() {
    super.onInit();
    _setupCallListeners();
  }

  @override
  void onClose() {
    _durationTimer?.cancel();
    _ringingTimer?.cancel();
    _audioPlayer.dispose();
    _removeCallListeners();
    super.onClose();
  }

  void _setupCallListeners() {
    _onCallCreated = (data) {
      _currentCallId = data['callId'];
      _channelName = data['channelId'];
      final calleeOnline = data['calleeOnline'] ?? false;
      if (!calleeOnline) {
        Get.snackbar('', '对方不在线，已发送通知');
      }
    };
    SocketService.to.onCallCreated(_onCallCreated!);

    _onCallIncoming = (data) {
      _currentCallId = data['callId'];
      _channelName = data['channelId'];
      remoteUserName.value = data['callerName'] ?? '';
      remoteUserAvatar.value = data['callerAvatar'] ?? '';
      isVideo.value = data['type'] == 'VIDEO';
      callState.value = CallState.ringing;
      _playRingtone();
      _showIncomingCall();
    };
    SocketService.to.onCallIncoming(_onCallIncoming!);

    _onCallAccepted = (data) async {
      _ringingTimer?.cancel();
      _audioPlayer.stop();
      callState.value = CallState.inCall;
      _startDurationTimer();

      // 加入 Agora 频道
      final tokenData = await _callProvider.getToken(data['channelId']);
      final token = tokenData['token'] ?? '';
      final appId = tokenData['appId'] ?? '';
      await RtcService.to.joinChannel(token, data['channelId'], isVideo: isVideo.value, appId: appId);
      // 呼叫方也导航到通话页面
      Get.off(() => const CallPage());
    };
    SocketService.to.onCallAccepted(_onCallAccepted!);

    _onCallRejected = (data) {
      _cleanup();
      _closeCallPages();
      Get.snackbar('', '对方已拒绝通话');
    };
    SocketService.to.onCallRejected(_onCallRejected!);

    _onCallEnded = (data) async {
      await RtcService.to.leaveChannel();
      _cleanup();
      // 关闭所有通话相关页面，返回聊天界面
      _closeCallPages();
    };
    SocketService.to.onCallEnded(_onCallEnded!);

    _onCallTimeout = (data) {
      _cleanup();
      _closeCallPages();
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.snackbar('', '对方未接听');
      });
    };
    SocketService.to.onCallTimeout(_onCallTimeout!);
  }

  void _removeCallListeners() {
    if (_onCallCreated != null) SocketService.to.off('call:created', _onCallCreated);
    if (_onCallIncoming != null) SocketService.to.off('call:incoming', _onCallIncoming);
    if (_onCallAccepted != null) SocketService.to.off('call:accepted', _onCallAccepted);
    if (_onCallRejected != null) SocketService.to.off('call:rejected', _onCallRejected);
    if (_onCallEnded != null) SocketService.to.off('call:ended', _onCallEnded);
    if (_onCallTimeout != null) SocketService.to.off('call:timeout', _onCallTimeout);
  }

  Future<void> startCall(String targetUserId, {bool video = false, String? conversationId, Map<String, dynamic>? arguments}) async {
    final hasPermission = await RtcService.to.requestPermissions(video: video);
    if (!hasPermission) {
      Get.snackbar('', '需要麦克风${video ? '和摄像头' : ''}权限');
      return;
    }

    isVideo.value = video;
    callState.value = CallState.outgoing;

    // 获取对方信息
    if (arguments != null) {
      remoteUserName.value = arguments['name'] ?? '';
      remoteUserAvatar.value = arguments['avatar'] ?? '';
    }

    SocketService.to.sendCallInvite(targetUserId, video ? 'VIDEO' : 'VOICE', conversationId: conversationId);
    _playWaitingTone();
    _showOutgoingCall();

    // 30s 超时
    _ringingTimer = Timer(const Duration(seconds: 30), () {
      if (callState.value == CallState.outgoing) {
        hangup();
        Get.snackbar('', '对方未接听');
      }
    });
  }

  Future<void> acceptCall() async {
    if (_currentCallId == null || _channelName == null) return;

    _ringingTimer?.cancel();
    _audioPlayer.stop();

    SocketService.to.sendCallAccept(_currentCallId!);

    // 获取 Token 并加入频道
    try {
      final tokenData = await _callProvider.getToken(_channelName!);
      final token = tokenData['token'] ?? '';
      final appId = tokenData['appId'] ?? '';
      await RtcService.to.joinChannel(token, _channelName!, isVideo: isVideo.value, appId: appId);
      callState.value = CallState.inCall;
      _startDurationTimer();
      // 导航到通话页面
      Get.off(() => const CallPage());
    } catch (e) {
      Get.snackbar('', '加入通话失败');
      hangup();
    }
  }

  void rejectCall() {
    if (_currentCallId == null) return;
    SocketService.to.sendCallReject(_currentCallId!);
    _cleanup();
    _closeCallPages();
  }

  void hangup() {
    if (_currentCallId == null) return;
    SocketService.to.sendCallHangup(_currentCallId!, duration: callDuration.value);
    RtcService.to.leaveChannel();
    _cleanup();
    _closeCallPages();
  }

  void toggleMute() => RtcService.to.toggleMute();
  void toggleSpeaker() => RtcService.to.toggleSpeaker();
  void toggleCamera() => RtcService.to.toggleCamera();
  void switchCamera() => RtcService.to.switchCamera();

  void _startDurationTimer() {
    callDuration.value = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration.value++;
    });
  }

  void _cleanup() {
    _durationTimer?.cancel();
    _ringingTimer?.cancel();
    _audioPlayer.stop();
    callState.value = CallState.idle;
    callDuration.value = 0;
    _currentCallId = null;
    _channelName = null;
  }

  void _closeCallPages() {
    // 关闭所有通话相关页面，返回聊天界面
    // 尝试多次返回，直到回到非通话页面
    int maxAttempts = 5;
    while (maxAttempts > 0) {
      final currentRoute = Get.currentRoute;
      if (!currentRoute.contains('CallPage') &&
          !currentRoute.contains('IncomingCallPage') &&
          !currentRoute.contains('OutgoingCallPage')) {
        break;
      }
      Get.back();
      maxAttempts--;
    }
  }

  void _playRingtone() {
    try {
      _audioPlayer.play(AssetSource('sounds/incoming_call.mp3'), volume: 0.8);
    } catch (_) {
      // 铃声文件不存在时静默处理
    }
  }

  void _playWaitingTone() {
    try {
      _audioPlayer.play(AssetSource('sounds/waiting_tone.mp3'), volume: 0.6);
    } catch (_) {
      // 等待音文件不存在时静默处理
    }
  }

  void _showIncomingCall() {
    Get.to(() => const IncomingCallPage(), opaque: false);
  }

  void _showOutgoingCall() {
    Get.to(() => const OutgoingCallPage(), opaque: false);
  }

  String get formattedDuration {
    final min = callDuration.value ~/ 60;
    final sec = callDuration.value % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
