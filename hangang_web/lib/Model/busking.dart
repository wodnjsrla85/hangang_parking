// busking.dart
import 'dart:convert';

// Model/busking.dart (핵심만)
class Busking {
  final String? id;      // ✅ Mongo _id (string으로 수신)
  final String userid;
  final String name;
  final String date;
  final String category;
  final String content;
  final String bandName;
  final int state;

  Busking({
    this.id,
    required this.userid,
    required this.name,
    required this.date,
    required this.category,
    required this.content,
    required this.bandName,
    required this.state,
  });

  factory Busking.fromJson(Map<String, dynamic> json) => Busking(
        id: json['_id'] as String?,                 // ✅ _id 매핑
        userid: json['userid'] as String,
        name: json['name'] as String,
        date: json['date'] as String,
        category: json['category'] as String,
        content: json['content'] as String,
        bandName: json['bandName'] as String,
        state: (json['state'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        // insert 시 _id는 서버가 생성
        'userid': userid,
        'name': name,
        'date': date,
        'category': category,
        'content': content,
        'bandName': bandName,
        'state': state,
      };

  Busking copyWith({
    String? id,
    String? userid,
    String? name,
    String? date,
    String? category,
    String? content,
    String? bandName,
    int? state,
  }) {
    return Busking(
      id: id ?? this.id,
      userid: userid ?? this.userid,
      name: name ?? this.name,
      date: date ?? this.date,
      category: category ?? this.category,
      content: content ?? this.content,
      bandName: bandName ?? this.bandName,
      state: state ?? this.state,
    );
  }
}