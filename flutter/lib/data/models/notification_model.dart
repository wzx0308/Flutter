class NotificationModel {
  final String id;
  final String? userId;
  final String? actorId;
  final String? type;
  final String? targetType;
  final String? targetId;
  final String? content;
  final bool isRead;
  final String? createdAt;
  final NotificationActor? actor;

  NotificationModel({
    required this.id,
    this.userId,
    this.actorId,
    this.type,
    this.targetType,
    this.targetId,
    this.content,
    this.isRead = false,
    this.createdAt,
    this.actor,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'],
      actorId: json['actorId'],
      type: json['type'],
      targetType: json['targetType'],
      targetId: json['targetId'],
      content: json['content'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'],
      actor: json['actor'] != null ? NotificationActor.fromJson(json['actor']) : null,
    );
  }
}

class NotificationActor {
  final String id;
  final String? username;
  final String? nickname;
  final String? avatar;

  NotificationActor({required this.id, this.username, this.nickname, this.avatar});

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      id: json['id'] ?? '',
      username: json['username'],
      nickname: json['nickname'],
      avatar: json['avatar'],
    );
  }

  String get displayName => nickname ?? username ?? 'User';
}
