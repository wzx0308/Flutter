import 'user_model.dart';

class PostModel {
  final String id;
  final String? authorId;
  final String? type;
  final String? content;
  final String? title;
  final String? coverImage;
  final List<String>? images;
  final List<String>? tags;
  final String? locationName;
  final int? likeCount;
  final int? commentCount;
  final int? shareCount;
  final String? status;
  final String? createdAt;
  final UserModel? author;
  final bool? isLiked;
  final bool? isBookmarked;

  PostModel({
    required this.id,
    this.authorId,
    this.type,
    this.content,
    this.title,
    this.coverImage,
    this.images,
    this.tags,
    this.locationName,
    this.likeCount,
    this.commentCount,
    this.shareCount,
    this.status,
    this.createdAt,
    this.author,
    this.isLiked,
    this.isBookmarked,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      authorId: json['authorId'],
      type: json['type'],
      content: json['content'],
      title: json['title'],
      coverImage: json['coverImage'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      locationName: json['locationName'],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      status: json['status'],
      createdAt: json['createdAt'],
      author: json['author'] != null ? UserModel.fromJson(json['author']) : null,
      isLiked: json['isLiked'],
      isBookmarked: json['isBookmarked'],
    );
  }

  bool get isArticle => type == 'ARTICLE';
}
