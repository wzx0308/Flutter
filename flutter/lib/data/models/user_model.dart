class UserModel {
  final String id;
  final String? username;
  final String? nickname;
  final String? avatar;
  final String? bio;
  final String? email;
  final String? phone;
  final String? gender;
  final String? birthday;
  final String? location;
  final String? role;
  final String? status;
  final int? followerCount;
  final int? followingCount;
  final int? postCount;
  final String? createdAt;

  UserModel({
    required this.id,
    this.username,
    this.nickname,
    this.avatar,
    this.bio,
    this.email,
    this.phone,
    this.gender,
    this.birthday,
    this.location,
    this.role,
    this.status,
    this.followerCount,
    this.followingCount,
    this.postCount,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'],
      nickname: json['nickname'],
      avatar: json['avatar'],
      bio: json['bio'],
      email: json['email'],
      phone: json['phone'],
      gender: json['gender'],
      birthday: json['birthday'],
      location: json['location'],
      role: json['role'],
      status: json['status'],
      followerCount: json['followerCount'],
      followingCount: json['followingCount'],
      postCount: json['postCount'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'bio': bio,
      'email': email,
      'phone': phone,
      'gender': gender,
      'birthday': birthday,
      'location': location,
      'role': role,
      'status': status,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'postCount': postCount,
      'createdAt': createdAt,
    };
  }

  String get displayName => nickname ?? username ?? 'User';
}
