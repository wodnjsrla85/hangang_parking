class Comment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String createdAt;
  final String updatedAt;
  final bool deleted;
  final String? deletedAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
    this.deletedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
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
      'postId': postId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deleted': deleted,
      'deletedAt': deletedAt,
    };
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? content,
    String? createdAt,
    String? updatedAt,
    bool? deleted,
    String? deletedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
