class PostLike {
  final String id;
  final String postId;
  final String userId;
  final String createdAt;
  final String? updatedAt;

  PostLike({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  factory PostLike.fromJson(Map<String, dynamic> json) {
    return PostLike(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
