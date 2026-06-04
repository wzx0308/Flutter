class AiMessageModel {
  final String id;
  final String conversationId;
  final String role; // 'user' or 'assistant'
  String content;
  final List<String> images; // image URLs or base64 data URIs
  final DateTime createdAt;
  bool isStreaming;

  AiMessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.images = const [],
    required this.createdAt,
    this.isStreaming = false,
  });

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    return AiMessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isStreaming: json['isStreaming'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'role': role,
        'content': content,
        'images': images,
        'createdAt': createdAt.toIso8601String(),
        'isStreaming': false,
      };
}
