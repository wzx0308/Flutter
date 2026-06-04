import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../storage/storage_service.dart';
import '../constants/app_constants.dart';

class SocketService extends GetxService {
  static SocketService get to => Get.find();

  IO.Socket? _socket;
  final isConnected = false.obs;

  Future<SocketService> init() async {
    return this;
  }

  void connect() {
    final token = StorageService.to.getToken();
    if (token == null) return;

    _socket = IO.io(
      '${AppConstants.baseUrl.replaceFirst('/api', '')}/chat',
      IO.OptionBuilder()
          .setAuth({'token': token})
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      isConnected.value = true;
    });

    _socket!.onDisconnect((_) {
      isConnected.value = false;
    });

    _socket!.onConnectError((err) {
      isConnected.value = false;
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    isConnected.value = false;
  }

  void sendMessage(String conversationId, String content, {String type = 'TEXT', String? mediaUrl}) {
    _socket?.emit('chat:send', {
      'conversationId': conversationId,
      'content': content,
      'type': type,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    });
  }

  void sendTyping(String conversationId) {
    _socket?.emit('chat:typing', {'conversationId': conversationId});
  }

  void markRead(String conversationId) {
    _socket?.emit('chat:read', {'conversationId': conversationId});
  }

  void onReceiveMessage(dynamic Function(dynamic) callback) {
    _socket?.on('chat:receive', callback);
  }

  void onTyping(dynamic Function(dynamic) callback) {
    _socket?.on('chat:typing', callback);
  }

  void onReadAck(dynamic Function(dynamic) callback) {
    _socket?.on('chat:read:ack', callback);
  }

  void onUserStatus(dynamic Function(dynamic) callback) {
    _socket?.on('user:status', callback);
  }

  void onNotification(dynamic Function(dynamic) callback) {
    _socket?.on('notification:new', callback);
  }

  void onNotificationCount(dynamic Function(dynamic) callback) {
    _socket?.on('notification:count', callback);
  }

  void onRestricted(dynamic Function(dynamic) callback) {
    _socket?.on('chat:restricted', callback);
  }

  void off(String event, [dynamic Function(dynamic)? callback]) {
    if (callback != null) {
      _socket?.off(event, callback);
    } else {
      _socket?.off(event);
    }
  }

  // ═══════════════ Call Signaling ═══════════════

  void sendCallInvite(String userId, String type, {String? conversationId}) {
    _socket?.emit('call:invite', {
      'userId': userId,
      'type': type,
      if (conversationId != null) 'conversationId': conversationId,
    });
  }

  void sendCallAccept(String callId) {
    _socket?.emit('call:accept', {'callId': callId});
  }

  void sendCallReject(String callId) {
    _socket?.emit('call:reject', {'callId': callId});
  }

  void sendCallHangup(String callId, {int? duration}) {
    _socket?.emit('call:hangup', {
      'callId': callId,
      if (duration != null) 'duration': duration,
    });
  }

  void onCallCreated(dynamic Function(dynamic) callback) {
    _socket?.on('call:created', callback);
  }

  void onCallIncoming(dynamic Function(dynamic) callback) {
    _socket?.on('call:incoming', callback);
  }

  void onCallAccepted(dynamic Function(dynamic) callback) {
    _socket?.on('call:accepted', callback);
  }

  void onCallRejected(dynamic Function(dynamic) callback) {
    _socket?.on('call:rejected', callback);
  }

  void onCallEnded(dynamic Function(dynamic) callback) {
    _socket?.on('call:ended', callback);
  }

  void onCallTimeout(dynamic Function(dynamic) callback) {
    _socket?.on('call:timeout', callback);
  }
}
