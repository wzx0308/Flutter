class MessageModel {
  final String id;
  final String? conversationId;
  final String? senderId;
  final String? type;
  final String? content;
  final String? mediaUrl;
  final String? status;
  final String? senderName;
  final String? senderAvatar;
  final String? createdAt;

  MessageModel({
    required this.id,
    this.conversationId,
    this.senderId,
    this.type,
    this.content,
    this.mediaUrl,
    this.status,
    this.senderName,
    this.senderAvatar,
    this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'],
      senderId: json['senderId'],
      type: json['type'] ?? 'TEXT',
      content: json['content'],
      mediaUrl: json['mediaUrl'],
      status: json['status'],
      senderName: json['senderName'] ?? json['sender']?['nickname'],
      senderAvatar: json['senderAvatar'] ?? json['sender']?['avatar'],
      createdAt: json['createdAt'],
    );
  }
}
