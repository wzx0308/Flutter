import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class RtcService extends GetxService {
  static RtcService get to => Get.find();

  RtcEngine? _engine;
  bool _initialized = false;
  String _appId = '';
  final isJoined = false.obs;
  final isMuted = false.obs;
  final isSpeakerOn = true.obs;
  final isCameraOff = false.obs;
  final isFrontCamera = true.obs;
  final remoteUid = 0.obs;

  // 事件回调
  Function()? onUserJoined;
  Function()? onUserOffline;
  Function()? onJoinChannelSuccess;
  Function(String)? onConnectionStateChanged;

  Future<void> _ensureEngine({String? appId}) async {
    if (appId != null && appId.isNotEmpty) {
      _appId = appId;
    }
    if (_initialized && _engine != null) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: _appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        isJoined.value = true;
        onJoinChannelSuccess?.call();
      },
      onLeaveChannel: (connection, stats) {
        isJoined.value = false;
        remoteUid.value = 0;
      },
      onUserJoined: (connection, remoteUid2, elapsed) {
        remoteUid.value = remoteUid2;
        onUserJoined?.call();
      },
      onUserOffline: (connection, remoteUid2, reason) {
        remoteUid.value = 0;
        onUserOffline?.call();
      },
      onConnectionStateChanged: (connection, state, reason) {
        onConnectionStateChanged?.call(state.name);
      },
    ));

    _initialized = true;
  }

  Future<bool> requestPermissions({bool video = false}) async {
    if (kIsWeb) return true; // Web 端权限由浏览器管理
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;

    if (video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) return false;
    }
    return true;
  }

  Future<void> joinChannel(String token, String channelName, {bool isVideo = false, String? appId}) async {
    await _ensureEngine(appId: appId);

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    if (isVideo) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    } else {
      await _engine!.disableVideo();
      await _engine!.enableAudio();
    }

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> leaveChannel() async {
    if (_engine == null) return;
    await _engine!.leaveChannel();
    isJoined.value = false;
    isMuted.value = false;
    isSpeakerOn.value = true;
    isCameraOff.value = false;
    isFrontCamera.value = true;
    remoteUid.value = 0;
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    _engine?.muteLocalAudioStream(isMuted.value);
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    _engine?.setEnableSpeakerphone(isSpeakerOn.value);
  }

  void toggleCamera() {
    isCameraOff.value = !isCameraOff.value;
    _engine?.muteLocalVideoStream(isCameraOff.value);
  }

  void switchCamera() {
    isFrontCamera.value = !isFrontCamera.value;
    _engine?.switchCamera();
  }

  void disposeEngine() {
    _engine?.release();
    _engine = null;
    _initialized = false;
  }

  RtcEngine? get engine => _engine;
}
