class RagDocumentModel {
  final String id;
  final String userId;
  final String? conversationId;
  final String filename;
  final String originalName;
  final String mimeType;
  final int fileSize;
  final String status;
  final int chunkCount;
  final String? errorMessage;
  final DateTime createdAt;

  RagDocumentModel({
    required this.id,
    required this.userId,
    this.conversationId,
    required this.filename,
    required this.originalName,
    required this.mimeType,
    required this.fileSize,
    required this.status,
    required this.chunkCount,
    this.errorMessage,
    required this.createdAt,
  });

  factory RagDocumentModel.fromJson(Map<String, dynamic> json) {
    return RagDocumentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      conversationId: json['conversationId'] ?? json['conversation_id'],
      filename: json['filename'] ?? '',
      originalName: json['originalName'] ?? json['original_name'] ?? '',
      mimeType: json['mimeType'] ?? json['mime_type'] ?? '',
      fileSize: json['fileSize'] ?? json['file_size'] ?? 0,
      status: json['status'] ?? 'processing',
      chunkCount: json['chunkCount'] ?? json['chunk_count'] ?? 0,
      errorMessage: json['errorMessage'] ?? json['error_message'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isIndexed => status == 'indexed';
  bool get isProcessing => status == 'processing';
  bool get isError => status == 'error';

  String get fileSizeDisplay {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
