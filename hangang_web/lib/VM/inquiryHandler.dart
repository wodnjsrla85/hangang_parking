import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Model/inquiry.dart';
import '../Model/admin.dart';

class InquiryHandler {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // 상태 변수
  List<Inquiry> inquiries = [];
  bool isLoading = false;
  Admin? currentAdmin; // 현재 로그인된 관리자

  // 로그인 했는지 확인
  bool get isLoggedIn => currentAdmin != null;

  // 🔐 관리자 회원가입
  Future<String> adminSignup(String adminId, String password) async {
    try {
      isLoading = true;

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': adminId,
          'pw': password,
        }),
      );

      print('📡 응답 상태: ${response.statusCode}');
      print('📡 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['result'] == 'OK') {
          print('✅ 회원가입 성공: $adminId');
          return 'success';
        } else {
          return data['message'] ?? '회원가입 실패';
        }
      } else {
        return 'HTTP 오류: ${response.statusCode}';
      }
    } catch (e) {
      print('❌ 회원가입 오류: $e');
      return '네트워크 오류: $e';
    } finally {
      isLoading = false;
    }
  }

  // 🔐 관리자 로그인
  Future<bool> adminLogin(String adminId, String password) async {
    try {
      isLoading = true;

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': adminId,
          'pw': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['result'] == 'OK') {
          currentAdmin = Admin.fromJson(data['admin']);
          print('✅ 로그인 성공: ${currentAdmin!.id}');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ 로그인 오류: $e');
      return false;
    } finally {
      isLoading = false;
    }
  }

  // 🔐 관리자 로그아웃
  Future<void> adminLogout() async {
    try {
      await http.post(Uri.parse('$baseUrl/api/admin/logout'));
    } catch (e) {
      // 에러 있어도 로그아웃 처리
    }
    
    currentAdmin = null;
    inquiries.clear();
    print('✅ 로그아웃 완료');
  }

  // 📋 모든 문의 조회 (기존 코드)
  Future<ApiResponse<List<Inquiry>>> fetchInquiries() async {
    try {
      isLoading = true;

      final response = await http.get(
        Uri.parse('$baseUrl/select'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        inquiries = results.map((json) => Inquiry.fromJson(json)).toList();
        inquiries.sort((a, b) => b.qDate.compareTo(a.qDate));

        return ApiResponse.success(inquiries, message: '문의 목록 불러오기 성공');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('문의 조회 실패: $e');
    } finally {
      isLoading = false;
    }
  }

  // ✏️ 답변 작성 (기존 코드)
  Future<ApiResponse<bool>> updateInquiry(String inquiryId, String answerContent) async {
    try {
      if (answerContent.trim().isEmpty) {
        return ApiResponse.error('답변 내용을 입력해주세요.');
      }

      final updateData = {
        'adminID': currentAdmin?.id ?? 'admin',
        'adate': DateTime.now().toIso8601String().split('T')[0],
        'answerContent': answerContent.trim(),
        'state': '답변완료',
      };

      final response = await http.put(
        Uri.parse('$baseUrl/update/$inquiryId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['result'] == 'OK') {
          final idx = inquiries.indexWhere((i) => i.id == inquiryId);
          if (idx != -1) {
            inquiries[idx] = inquiries[idx].copyWith(
              adminID: currentAdmin?.id ?? 'admin',
              aDate: DateTime.now().toIso8601String().split('T')[0],
              answerContent: answerContent.trim(),
              state: '답변완료',
            );
          }
          return ApiResponse.success(true, message: '답변 등록 성공');
        }
      }
      return ApiResponse.error('서버 응답 오류');
    } catch (e) {
      return ApiResponse.error('답변 등록 실패: $e');
    }
  }

  // 🔄 새로고침
  Future<void> refreshAllData() async {
    await fetchInquiries();
  }
}

// API 응답 클래스
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;

  ApiResponse.success(this.data, {required this.message}) : success = true;
  ApiResponse.error(this.message) : success = false, data = null;
}