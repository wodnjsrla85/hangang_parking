import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hangangweb/VM/buskingHandler.dart';
import 'package:hangangweb/VM/inquiryHandler.dart';
import 'package:hangangweb/View/busking/buskingview.dart';
import 'package:hangangweb/View/Community/community_admin_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:hangangweb/View/Inquiry/all_inquiry_view.dart';
// import 'package:hangangweb/View/Busking/all_busking_view.dart';
// import 'package:hangangweb/View/Board/all_board_view.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final InquiryHandler handler = InquiryHandler();
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    fetchDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/api/admin/dashboard"),
      );
      if (response.statusCode == 200) {
        setState(() {
          dashboardData = jsonDecode(response.body);
          isLoading = false;
        });
        _animationController.forward();
      } else {
        throw Exception("데이터 불러오기 실패");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터를 불러오는데 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "관리자 대시보드",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "데이터를 불러오는 중...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 환영 메시지
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "안녕하세요, ${handler.currentAdmin?.id ?? '관리자'}님!",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "오늘도 반포한강 웹서비스 관리에 수고하고 계시네요.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 통계 카드 섹션
                    const Text(
                      "📊 실시간 통계",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 상단 통계 카드들
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernStatCard(
                            "총 유저 수",
                            (dashboardData?["total_users"] ?? 0).toString(),
                            Icons.people_rounded,
                            const Color(0xFF3B82F6),
                            const Color(0xFFEFF6FF),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernStatCard(
                            "오늘 가입",
                            (dashboardData?["new_today"] ?? 0).toString(),
                            Icons.person_add_rounded,
                            const Color(0xFF10B981),
                            const Color(0xFFECFDF5),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernStatCard(
                            "오늘 문의 수",
                            (dashboardData?["inquiries_today"] ?? 0).toString(),
                            Icons.help_outline_rounded,
                            const Color(0xFF8B5CF6),
                            const Color(0xFFF3E8FF),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernStatCard(
                            "버스킹 신청 대기 수",
                            (dashboardData?["busking_today"] ?? 0).toString(),
                            Icons.music_note_rounded,
                            const Color(0xFFF59E0B),
                            const Color(0xFFFEF3C7),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 관리 메뉴 섹션
                    const Text(
                      "⚙️ 관리 페이지",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 관리 페이지 이동 버튼들
                    _buildManagementCard(
                      "문의 관리",
                      "사용자 문의사항을 확인하고 관리하세요",
                      Icons.help_outline_rounded,
                      const Color(0xFF8B5CF6),
                      () {
                        Get.to(() => AllInquiryView());
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    _buildManagementCard(
                      "버스킹 관리",
                      "버스킹 공연 신청 및 승인을 관리하세요",
                      Icons.music_note_rounded,
                      const Color(0xFFF59E0B),
                      () {
                        Get.to(() => Buskingview(handler: BuskingHandler()));
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildManagementCard(
                      "게시판 관리",
                      "커뮤니티 게시글과 댓글을 관리하세요",
                      Icons.forum_rounded,
                      const Color(0xFF06B6D4),
                      () {
                        Get.to(() => CommunityAdminView());
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildModernStatCard(
    String title,
    String value,
    IconData icon,
    Color primaryColor,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: backgroundColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isEnabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? color : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? const Color(0xFF1E293B) : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isEnabled ? const Color(0xFF64748B) : Colors.grey,
                        ),
                      ),
                      if (!isEnabled)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "준비 중",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isEnabled ? color : Colors.grey,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}