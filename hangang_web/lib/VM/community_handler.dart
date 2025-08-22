import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Model/community.dart';
import '../Model/admin.dart';

class CommunityHandler {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // 상태 변수
  List<Community> communities = [];
  bool isLoading = false;
  Admin? currentAdmin;
  String selectedCategory = '전체';

  // 로그인 확인
  bool get isLoggedIn => currentAdmin != null;

  // 통계 계산
  int get totalCount => communities.length;
  int get activeCount => communities.where((c) => !c.deleted).length;
  int get deletedCount => communities.where((c) => c.deleted).length;

  // 카테고리별 개수
  int getCountForCategory(String category) {
    switch (category) {
      case '활성':
        return activeCount;
      case '삭제됨':
        return deletedCount;
      default:
        return totalCount;
    }
  }

  // 🔐 관리자 로그인 (Admin 구조 변경에 따라 수정)
  Future<bool> adminLogin(String adminId, String password) async {
    try {
      isLoading = true;

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': adminId,
          'pw': password,  // 🔄 기존 그대로 유지
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['result'] == 'OK') {
          // 🔄 CHANGED: Admin 구조 변경에 따른 수정
          currentAdmin = Admin(
            id: data['admin']['id'] ?? adminId,
            date: DateTime.now().toIso8601String().split('T')[0], // 현재 날짜로 설정
          );
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

  // 🔐 관리자 로그아웃 (변경사항 없음)
  Future<void> adminLogout() async {
    try {
      await http.post(Uri.parse('$baseUrl/api/admin/logout'));
    } catch (e) {
      // 에러 있어도 로그아웃 처리
    }
    
    currentAdmin = null;
    communities.clear();
    print('✅ 로그아웃 완료');
  }

  // 📋 모든 커뮤니티 게시글 조회 (변경사항 없음)
  Future<ApiResponse<List<Community>>> fetchCommunities() async {
    try {
      isLoading = true;

      final response = await http.get(
        Uri.parse('$baseUrl/community/select'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 응답 상태: ${response.statusCode}');
      print('📡 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        communities = results.map((json) => Community.fromJson(json)).toList();
        communities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ApiResponse.success(communities, message: '커뮤니티 목록 불러오기 성공');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('커뮤니티 조회 실패: $e');
    } finally {
      isLoading = false;
    }
  }

  // 📋 특정 커뮤니티 게시글 조회 (변경사항 없음)
  Future<ApiResponse<Community>> fetchCommunity(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/community/select/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final community = Community.fromJson(data['result']);
        return ApiResponse.success(community, message: '커뮤니티 게시글 조회 성공');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('커뮤니티 게시글 조회 실패: $e');
    }
  }

  // ✏️ 커뮤니티 게시글 생성 (변경사항 없음)
  Future<ApiResponse<bool>> createCommunity(String userId, String content) async {
    try {
      if (content.trim().isEmpty) {
        return ApiResponse.error('내용을 입력해주세요.');
      }

      final createData = {
        'id': '',
        'userId': userId,
        'content': content.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'deleted': false,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/community/insert'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(createData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['result'] == 'OK') {
          await fetchCommunities();
          return ApiResponse.success(true, message: '커뮤니티 게시글 생성 성공');
        }
      }
      return ApiResponse.error('서버 응답 오류');
    } catch (e) {
      return ApiResponse.error('커뮤니티 게시글 생성 실패: $e');
    }
  }

  // ✏️ 커뮤니티 게시글 수정 (변경사항 없음)
  Future<ApiResponse<bool>> updateCommunity(String communityId, String content) async {
    try {
      if (content.trim().isEmpty) {
        return ApiResponse.error('내용을 입력해주세요.');
      }

      final updateData = {
        'content': content.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final response = await http.put(
        Uri.parse('$baseUrl/community/update/$communityId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['result'] == 'OK') {
          final idx = communities.indexWhere((c) => c.id == communityId);
          if (idx != -1) {
            communities[idx] = communities[idx].copyWith(
              content: content.trim(),
              updatedAt: DateTime.now().toIso8601String(),
            );
          }
          return ApiResponse.success(true, message: '커뮤니티 게시글 수정 성공');
        }
      }
      return ApiResponse.error('서버 응답 오류');
    } catch (e) {
      return ApiResponse.error('커뮤니티 게시글 수정 실패: $e');
    }
  }

  // 🗑️ 커뮤니티 게시글 삭제 (변경사항 없음)
  Future<ApiResponse<bool>> deleteCommunity(String communityId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/community/delete/$communityId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['result'] == 'OK') {
          final idx = communities.indexWhere((c) => c.id == communityId);
          if (idx != -1) {
            communities[idx] = communities[idx].copyWith(
              deleted: true,
              deletedAt: DateTime.now().toIso8601String(),
            );
          }
          return ApiResponse.success(true, message: '커뮤니티 게시글 삭제 성공');
        }
      }
      return ApiResponse.error('서버 응답 오류');
    } catch (e) {
      return ApiResponse.error('커뮤니티 게시글 삭제 실패: $e');
    }
  }

  // 📊 카테고리에 따른 커뮤니티 필터링 (변경사항 없음)
  List<Community> get filteredCommunities {
    switch (selectedCategory) {
      case '활성':
        return communities.where((c) => !c.deleted).toList();
      case '삭제됨':
        return communities.where((c) => c.deleted).toList();
      default:
        return communities;
    }
  }

  // 🔄 새로고침 (변경사항 없음)
  Future<void> refreshAllData() async {
    await fetchCommunities();
  }

  // 🔍 검색 기능 (변경사항 없음)
  List<Community> searchCommunities(String query) {
    if (query.trim().isEmpty) {
      return filteredCommunities;
    }
    
    return filteredCommunities.where((c) => 
      c.content.toLowerCase().contains(query.toLowerCase()) ||
      c.userId.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // 📈 사용자별 게시글 수 (변경사항 없음)
  Map<String, int> getUserPostCounts() {
    Map<String, int> counts = {};
    for (var community in communities.where((c) => !c.deleted)) {
      counts[community.userId] = (counts[community.userId] ?? 0) + 1;
    }
    return counts;
  }

  // 📈 일별 게시글 수 (변경사항 없음)
  Map<String, int> getDailyPostCounts() {
    Map<String, int> counts = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      counts[dateStr] = 0;
    }
    
    for (var community in communities.where((c) => !c.deleted)) {
      final createdDate = community.createdAt.split('T')[0];
      if (counts.containsKey(createdDate)) {
        counts[createdDate] = counts[createdDate]! + 1;
      }
    }
    
    return counts;
  }
}

// API 응답 클래스 (변경사항 없음)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;

  ApiResponse.success(this.data, {required this.message}) : success = true;
  ApiResponse.error(this.message) : success = false, data = null;
}
