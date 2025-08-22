import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Model/admin.dart';

class AdminHandler {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // 싱글톤 패턴으로 앱 전체에서 같은 인스턴스 사용
  static final AdminHandler _instance = AdminHandler._internal();
  factory AdminHandler() => _instance;
  AdminHandler._internal();

  // 상태 변수
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
    print('✅ 로그아웃 완료');
  }

  // 현재 관리자 ID 가져오기
  String get currentAdminId => currentAdmin?.id ?? 'admin';
}