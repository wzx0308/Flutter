import 'user_model.dart';

class CommentModel {
  final String id;
  final String? postId;
  final String? authorId;
  final String? parentId;
  final String? content;
  final int? likeCount;
  final String? status;
  final String? createdAt;
  final UserModel? author;
  final List<CommentModel>? replies;

  CommentModel({
    required this.id,
    this.postId,
    this.authorId,
    this.parentId,
    this.content,
    this.likeCount,
    this.status,
    this.createdAt,
    this.author,
    this.replies,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      postId: json['postId'],
      authorId: json['authorId'],
      parentId: json['parentId'],
      content: json['content'],
      likeCount: json['likeCount'] ?? 0,
      status: json['status'],
      createdAt: json['createdAt'],
      author: json['author'] != null ? UserModel.fromJson(json['author']) : null,
      replies: json['replies'] != null
          ? (json['replies'] as List).map((e) => CommentModel.fromJson(e)).toList()
          : null,
    );
  }
}
