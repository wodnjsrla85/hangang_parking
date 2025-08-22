import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Model/comment.dart';

class CommentHandler {
  static const String baseUrl = 'http://localhost:8000';
  List<Comment> comments = [];
  String selectedCategory = '전체';
  bool isLoading = false;
  String errorMessage = '';

  Future<bool> fetchAllComments() async {
    try {
      isLoading = true;
      errorMessage = '';
      
      final String fullUrl = '$baseUrl/comment/select';
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
        comments = (data['results'] as List)
            .map((json) => Comment.fromJson(json))
            .toList();
        
        comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        print('✅ 댓글 ${comments.length}개 로드 성공');
        return true;
      } else {
        errorMessage = '댓글 목록을 불러오는데 실패했습니다. 상태코드: ${response.statusCode}';
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

  List<Comment> get filteredComments {
    switch (selectedCategory) {
      case '전체':
        return comments;
      case '활성':
        return comments;
      case '삭제됨':
        return [];
      default:
        return comments;
    }
  }

  int get totalCount => comments.length;
  int get activeCount => comments.length;
  int get deletedCount => 0;

  List<Comment> searchComments(String query) {
    final lowerQuery = query.toLowerCase();
    final baseList = filteredComments;
    
    return baseList.where((comment) {
      return comment.content.toLowerCase().contains(lowerQuery) ||
             comment.userId.toLowerCase().contains(lowerQuery) ||
             comment.username.toLowerCase().contains(lowerQuery) ||
             comment.communityId.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<bool> updateComment(String commentId, String newContent) async {
    try {
      errorMessage = '';
      
      final response = await http.put(
        Uri.parse('$baseUrl/comment/update/$commentId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': newContent}),
      );

      if (response.statusCode == 200) {
        final index = comments.indexWhere((c) => c.id == commentId);
        if (index != -1) {
          comments[index] = Comment(
            id: comments[index].id,
            communityId: comments[index].communityId,
            userId: comments[index].userId,
            username: comments[index].username,
            content: newContent,
            createdAt: comments[index].createdAt,
            updatedAt: DateTime.now().toIso8601String(),
            deleted: comments[index].deleted,
            deletedAt: comments[index].deletedAt,
          );
        }
        return true;
      } else {
        errorMessage = '댓글 수정에 실패했습니다.';
        return false;
      }
    } catch (e) {
      errorMessage = '오류가 발생했습니다: $e';
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      errorMessage = '';
      
      final response = await http.delete(
        Uri.parse('$baseUrl/comment/delete/$commentId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        comments.removeWhere((c) => c.id == commentId);
        return true;
      } else {
        errorMessage = '댓글 삭제에 실패했습니다.';
        return false;
      }
    } catch (e) {
      errorMessage = '오류가 발생했습니다: $e';
      return false;
    }
  }
}
