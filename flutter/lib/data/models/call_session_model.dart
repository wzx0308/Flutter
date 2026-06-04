class CallSessionModel {
  final String id;
  final String callerId;
  final String calleeId;
  final String? conversationId;
  final String type;
  final String status;
  final String channelId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int duration;
  final DateTime? createdAt;
  final Map<String, dynamic>? caller;
  final Map<String, dynamic>? callee;

  CallSessionModel({
    required this.id,
    required this.callerId,
    required this.calleeId,
    this.conversationId,
    required this.type,
    required this.status,
    required this.channelId,
    this.startedAt,
    this.endedAt,
    this.duration = 0,
    this.createdAt,
    this.caller,
    this.callee,
  });

  factory CallSessionModel.fromJson(Map<String, dynamic> json) {
    return CallSessionModel(
      id: json['id'] ?? '',
      callerId: json['callerId'] ?? json['caller_id'] ?? '',
      calleeId: json['calleeId'] ?? json['callee_id'] ?? '',
      conversationId: json['conversationId'] ?? json['conversation_id'],
      type: json['type'] ?? 'VOICE',
      status: json['status'] ?? 'RINGING',
      channelId: json['channelId'] ?? json['channel_id'] ?? '',
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.tryParse(json['endedAt']) : null,
      duration: json['duration'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      caller: json['caller'],
      callee: json['callee'],
    );
  }

  String get statusText {
    switch (status) {
      case 'RINGING': return '呼叫中';
      case 'ACCEPTED': return '通话中';
      case 'REJECTED': return '已拒绝';
      case 'MISSED': return '未接听';
      case 'TIMEOUT': return '未接听';
      case 'ENDED': return '通话结束';
      default: return status;
    }
  }

  String get typeText => type == 'VIDEO' ? '视频通话' : '语音通话';

  String get durationText {
    if (duration <= 0) return '';
    final min = duration ~/ 60;
    final sec = duration % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
