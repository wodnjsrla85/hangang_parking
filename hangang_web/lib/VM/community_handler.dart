import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Model/community.dart';

class CommunityHandler {
  static const String baseUrl = 'http://localhost:8000';
  List<Community> communities = [];
  String selectedCategory = '전체';
  bool isLoading = false;
  bool isLoggedIn = true;
  Admin? currentAdmin;
  String errorMessage = '';

  Future<bool> fetchCommunities() async {
    try {
      isLoading = true;
      errorMessage = '';
      
      final String fullUrl = '$baseUrl/community/select';
      print('🔍 API 호출 시도: $fullUrl');
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📝 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        communities = (data['results'] as List)
            .map((json) => Community.fromJson(json))
            .toList();
        
        communities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        print('✅ 커뮤니티 ${communities.length}개 로드 성공');
        return true;
      } else {
        errorMessage = '커뮤니티 목록을 불러오는데 실패했습니다. 상태코드: ${response.statusCode}';
        print('❌ API 오류: $errorMessage');
        return false;
      }
    } catch (e) {
      errorMessage = '오류가 발생했습니다: $e';
      print('🚨 예외 발생: $e');
      return false;
    } finally {
      isLoading = false;
    }
  }

  List<Community> get filteredCommunities {
    switch (selectedCategory) {
      case '전체':
        return communities;
      case '활성':
        return communities;
      case '삭제됨':
        return [];
      default:
        return communities;
    }
  }

  int get totalCount => communities.length;
  int get activeCount => communities.length;
  int get deletedCount => 0;

  List<Community> searchCommunities(String query) {
    final lowerQuery = query.toLowerCase();
    final baseList = filteredCommunities;
    
    return baseList.where((community) {
      return community.content.toLowerCase().contains(lowerQuery) ||
             community.userId.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<bool> updateCommunity(String communityId, String newContent) async {
    try {
      errorMessage = '';
      
      final response = await http.put(
        Uri.parse('$baseUrl/community/update/$communityId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': newContent}),
      );

      if (response.statusCode == 200) {
        final index = communities.indexWhere((c) => c.id == communityId);
        if (index != -1) {
          communities[index] = Community(
            id: communities[index].id,
            userId: communities[index].userId,
            content: newContent,
            createdAt: communities[index].createdAt,
            updatedAt: DateTime.now().toIso8601String(),
            deleted: communities[index].deleted,
            deletedAt: communities[index].deletedAt,
          );
        }
        return true;
      } else {
        errorMessage = '게시글 수정에 실패했습니다.';
        return false;
      }
    } catch (e) {
      errorMessage = '오류가 발생했습니다: $e';
      return false;
    }
  }

  Future<bool> deleteCommunity(String communityId) async {
    try {
      errorMessage = '';
      
      final response = await http.delete(
        Uri.parse('$baseUrl/community/delete/$communityId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        communities.removeWhere((c) => c.id == communityId);
        return true;
      } else {
        errorMessage = '게시글 삭제에 실패했습니다.';
        return false;
      }
    } catch (e) {
      errorMessage = '오류가 발생했습니다: $e';
      return false;
    }
  }

  Future<void> adminLogout() async {
    isLoggedIn = false;
    currentAdmin = null;
    communities.clear();
  }
}

class Admin {
  final String id;
  final String name;

  Admin({required this.id, required this.name});

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
