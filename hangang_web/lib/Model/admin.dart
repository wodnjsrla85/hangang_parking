class Admin {
  final String id;
  final String date;

  Admin({
    required this.id,
    required this.date,
  });

  // JSON에서 Admin 만들기
  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
    );
  }

  // Admin을 JSON으로 만들기
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
    };
  }
}