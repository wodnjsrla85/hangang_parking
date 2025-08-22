class Comment {
  final String id;
  final String communityId;
  final String userId;
  final String username;
  final String content;
  final String createdAt;
  final String updatedAt;
  final bool deleted;
  final String? deletedAt;

  Comment({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    this.deletedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      communityId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      deleted: json['deleted'] ?? false,
      deletedAt: json['deletedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': communityId,
      'userId': userId,
      'username': username,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deleted': deleted,
      'deletedAt': deletedAt,
    };
  }
}
