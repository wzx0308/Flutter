class ConversationModel {
  final String id;
  final String? type;
  final String? name;
  final String? avatar;
  final List<dynamic>? members;
  final LastMessage? lastMessage;
  final int unreadCount;
  final String? updatedAt;
  final bool isMutualFollow;
  final bool isPinned;
  final bool isMuted;

  ConversationModel({
    required this.id,
    this.type,
    this.name,
    this.avatar,
    this.members,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
    this.isMutualFollow = false,
    this.isPinned = false,
    this.isMuted = false,
  });

  ConversationModel copyWith({
    String? id,
    String? type,
    String? name,
    String? avatar,
    List<dynamic>? members,
    LastMessage? lastMessage,
    int? unreadCount,
    String? updatedAt,
    bool? isMutualFollow,
    bool? isPinned,
    bool? isMuted,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      isMutualFollow: isMutualFollow ?? this.isMutualFollow,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? '',
      type: json['type'],
      name: json['name'],
      avatar: json['avatar'],
      members: json['members'],
      lastMessage: json['lastMessage'] != null ? LastMessage.fromJson(json['lastMessage']) : null,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: json['updatedAt'],
      isMutualFollow: json['isMutualFollow'] ?? false,
      isPinned: json['isPinned'] ?? false,
      isMuted: json['isMuted'] ?? false,
    );
  }
}

class LastMessage {
  final String? id;
  final String? content;
  final String? type;
  final String? senderId;
  final String? senderName;
  final String? createdAt;

  LastMessage({this.id, this.content, this.type, this.senderId, this.senderName, this.createdAt});

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      id: json['id'],
      content: json['content'],
      type: json['type'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      createdAt: json['createdAt'],
    );
  }
}
