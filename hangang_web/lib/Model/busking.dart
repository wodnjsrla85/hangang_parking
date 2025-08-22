// busking.dart
import 'dart:convert';

class Busking {
  final String? id;        // MongoDB _id -> id로 매핑
  final String userid;
  final String name;
  final String date;       // 서버가 문자열로 받으므로 String 유지
  final String category;
  final String content;
  final String bandName;
  final int state;

  const Busking({
    this.id,
    required this.userid,
    required this.name,
    required this.date,
    required this.category,
    required this.content,
    required this.bandName,
    required this.state,
  });

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

  factory Busking.fromJson(Map<String, dynamic> json) {
    return Busking(
      id: json['_id'] as String?,           // normalize_busking가 _id를 문자열로 반환
      userid: json['userid'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      category: json['category'] as String,
      content: json['content'] as String,
      bandName: json['bandName'] as String,
      state: (json['state'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // insert/update 시 서버는 _id를 받지 않음
      'userid': userid,
      'name': name,
      'date': date,
      'category': category,
      'content': content,
      'bandName': bandName,
      'state': state,
    };
  }

  static List<Busking> listFromSelectResponse(Map<String, dynamic> json) {
    // FastAPI /busking/select 응답: { "results": [...] }
    final list = (json['results'] as List).cast<Map<String, dynamic>>();
    return list.map(Busking.fromJson).toList();
  }

  @override
  String toString() => jsonEncode({
        'id': id,
        ...toJson(),
      });
}