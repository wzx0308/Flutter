class AiConversationModel {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;
  bool isDeepThinking;
  int messageCount;

  AiConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isDeepThinking = false,
    this.messageCount = 0,
  });

  factory AiConversationModel.fromJson(Map<String, dynamic> json) {
    return AiConversationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '新对话',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isPinned: json['isPinned'] ?? false,
      isDeepThinking: json['isDeepThinking'] ?? false,
      messageCount: json['messageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isPinned': isPinned,
        'isDeepThinking': isDeepThinking,
        'messageCount': messageCount,
      };

  AiConversationModel copyWith({
    String? title,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isDeepThinking,
    int? messageCount,
  }) {
    return AiConversationModel(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isDeepThinking: isDeepThinking ?? this.isDeepThinking,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}
