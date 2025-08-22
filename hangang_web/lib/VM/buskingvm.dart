
import 'dart:convert';

import 'package:hangangweb/Model/busking.dart';
import 'package:hangangweb/VM/inquiryHandler.dart';
import 'package:http/http.dart' as http;

class BuskingHandler {
  // 필요 시 도메인으로 교체
  static const String baseUrl = 'http://127.0.0.1:8000';

  // 상태
  List<Busking> buskingList = [];
  bool isLoading = false;

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

  // 📋 전체 조회: GET /busking/select
  Future<ApiResponse<List<Busking>>> fetchBuskingList() async {
    try {
      isLoading = true;

      final res = await http.get(
        Uri.parse('$baseUrl/busking/select'),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body) as Map<String, dynamic>;
        final List<dynamic> results = decoded['results'] ?? [];
        buskingList =
            results.map((e) => Busking.fromJson(e as Map<String, dynamic>)).toList();

        // date 기준 내림차순 정렬(서버가 'YYYY-MM-DD' 포맷 가정)
        buskingList.sort((a, b) => b.date.compareTo(a.date));

        return ApiResponse.success(buskingList, message: '버스킹 목록 불러오기 성공');
      } else {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      return ApiResponse.error('버스킹 조회 실패: $e');
    } finally {
      isLoading = false;
    }
  }

  // ➕ 삽입: POST /busking/insert
  Future<ApiResponse<bool>> insertBusking(Busking b) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/busking/insert'),
        headers: _headers,
        body: json.encode(b.toJson()),
      );

      if (res.statusCode == 200) {
        // 낙관적 업데이트(선택): 서버가 _id를 바로 주지 않으므로, 재조회 권장
        await fetchBuskingList();
        return ApiResponse.success(true, message: '버스킹 등록 성공');
      } else {
        final msg = '등록 실패: HTTP ${res.statusCode} ${res.body}';
        return ApiResponse.error(msg);
      }
    } catch (e) {
      return ApiResponse.error('버스킹 등록 실패: $e');
    }
  }

  // ✏️ 부분 업데이트: PUT /busking/update/{userid}
  // 변경할 필드만 patch에 담아 전송 (예: {'state': 1, 'content': '수정'})
  Future<ApiResponse<bool>> updateBuskingByUserId(
    String userid,
    Map<String, dynamic> patch,
  ) async {
    try {
      if (patch.isEmpty) {
        return ApiResponse.error('수정할 필드가 없습니다.');
      }

      final res = await http.put(
        Uri.parse('$baseUrl/busking/update/$userid'),
        headers: _headers,
        body: json.encode(patch),
      );

      if (res.statusCode == 200) {
        // 로컬 상태 갱신 (필요 시 재조회)
        final idx = buskingList.indexWhere((e) => e.userid == userid);
        if (idx != -1) {
          final old = buskingList[idx];
          buskingList[idx] = old.copyWith(
            userid: (patch['userid'] ?? old.userid) as String?,
            name: (patch['name'] ?? old.name) as String?,
            date: (patch['date'] ?? old.date) as String?,
            category: (patch['category'] ?? old.category) as String?,
            content: (patch['content'] ?? old.content) as String?,
            bandName: (patch['bandName'] ?? old.bandName) as String?,
            state: patch['state'] != null ? (patch['state'] as num).toInt() : old.state,
          );
        }
        return ApiResponse.success(true, message: '버스킹 수정 성공');
      } else {
        final msg = '수정 실패: HTTP ${res.statusCode} ${res.body}';
        return ApiResponse.error(msg);
      }
    } catch (e) {
      return ApiResponse.error('버스킹 수정 실패: $e');
    }
  }

  // 🗑️ 삭제: DELETE /busking/delete/{userid}
  Future<ApiResponse<bool>> deleteBuskingByUserId(String userid) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/busking/delete/$userid'),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        buskingList.removeWhere((e) => e.userid == userid);
        return ApiResponse.success(true, message: '버스킹 삭제 성공');
      } else {
        final msg = '삭제 실패: HTTP ${res.statusCode} ${res.body}';
        return ApiResponse.error(msg);
      }
    } catch (e) {
      return ApiResponse.error('버스킹 삭제 실패: $e');
    }
  }

  // 🔄 새로고침
  Future<void> refreshAll() async {
    await fetchBuskingList();
  }
}