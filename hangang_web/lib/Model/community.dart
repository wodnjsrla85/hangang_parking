class Community {
  final String id;
  final String userId;
  final String content;
  final String createdAt;
  final String updatedAt;
  final bool deleted;
  final String? deletedAt;

  Community({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    this.deletedAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] ?? '',
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
      'userId': userId,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deleted': deleted,
      'deletedAt': deletedAt,
    };
  }
}
