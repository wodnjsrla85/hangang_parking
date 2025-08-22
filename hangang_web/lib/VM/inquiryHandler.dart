import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Model/inquiry.dart';
import 'adminHandler.dart'; // AdminHandler import

class InquiryHandler {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // AdminHandler 인스턴스 (싱글톤)
  final AdminHandler adminHandler = AdminHandler();

  // 상태 변수
  List<Inquiry> inquiries = [];
  bool isLoading = false;

  // 📋 모든 문의 조회
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

  // ✏️ 답변 작성
  Future<ApiResponse<bool>> updateInquiry(String inquiryId, String answerContent) async {
    try {
      if (answerContent.trim().isEmpty) {
        return ApiResponse.error('답변 내용을 입력해주세요.');
      }

      final updateData = {
        'adminID': adminHandler.currentAdminId,
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
              adminID: adminHandler.currentAdminId,
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

  // 관리자 관련 메서드들 (AdminHandler로 위임)
  bool get isLoggedIn => adminHandler.isLoggedIn;
  String get currentAdminId => adminHandler.currentAdminId;
  get currentAdmin => adminHandler.currentAdmin;
  
  Future<String> adminSignup(String adminId, String password) => 
    adminHandler.adminSignup(adminId, password);
  
  Future<bool> adminLogin(String adminId, String password) => 
    adminHandler.adminLogin(adminId, password);
  
  Future<void> adminLogout() => adminHandler.adminLogout();
}

// API 응답 클래스
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;

  ApiResponse.success(this.data, {required this.message}) : success = true;
  ApiResponse.error(this.message) : success = false, data = null;
}