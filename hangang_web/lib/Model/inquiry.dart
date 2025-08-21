// lib/Model/inquiry.dart

class Inquiry {
  String id;              // MongoDB ObjectId
  String userID;          // 작성자 ID (UI 표시용)
  String? adminID;        // null 가능
  String qDate;
  String? aDate;          // null 가능
  String title;
  String content;
  String? answerContent;  // null 가능
  String state;

  Inquiry({
    required this.id,
    required this.userID,
    this.adminID,
    required this.qDate,
    this.aDate,
    required this.title,
    required this.content,
    this.answerContent,
    required this.state,
  });

  // JSON → Inquiry 객체
  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['_id'] ?? '',        // MongoDB ObjectId
      userID: json['userID'] ?? '', // 작성자 ID
      adminID: json['adminID'],
      qDate: json['qdate'] ?? '',
      aDate: json['adate'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      answerContent: json['answerContent'],
      state: json['state'] ?? '대기중',
    );
  }

  // Inquiry → JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userID': userID,
      'adminID': adminID,
      'qdate': qDate,
      'adate': aDate,
      'title': title,
      'content': content,
      'answerContent': answerContent,
      'state': state,
    };
  }

  // API 전송용 JSON (null 필드 제외)
  Map<String, dynamic> toApiJson() {
    final Map<String, dynamic> data = {
      'userID': userID,
      'qdate': qDate,
      'title': title,
      'content': content,
      'state': state,
    };

    if (adminID != null) data['adminID'] = adminID;
    if (aDate != null) data['adate'] = aDate;
    if (answerContent != null) data['answerContent'] = answerContent;

    return data;
  }

  // 상태 확인
  bool get isAnswered => state == '답변완료';
  bool get isPending => state == '대기중';

  // 객체 복사
  Inquiry copyWith({
    String? id,
    String? userID,
    String? adminID,
    String? qDate,
    String? aDate,
    String? title,
    String? content,
    String? answerContent,
    String? state,
  }) {
    return Inquiry(
      id: id ?? this.id,
      userID: userID ?? this.userID,
      adminID: adminID ?? this.adminID,
      qDate: qDate ?? this.qDate,
      aDate: aDate ?? this.aDate,
      title: title ?? this.title,
      content: content ?? this.content,
      answerContent: answerContent ?? this.answerContent,
      state: state ?? this.state,
    );
  }

  @override
  String toString() {
    return 'Inquiry{id: $id, userID: $userID, title: $title, state: $state}';
  }
}

// ✅ Inquiry 파일 안에 같이 둔 ApiResponse
class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;

  ApiResponse._({this.data, this.message, required this.success});

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse._(data: data, message: message, success: true);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse._(message: message, success: false);
  }

  @override
  String toString() =>
      'ApiResponse(success: $success, message: $message, data: $data)';
}
