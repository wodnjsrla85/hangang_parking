import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hangangweb/View/community_admin_view.dart';
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

class _HomeState extends State<Home> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final response =
        await http.get(Uri.parse("http://127.0.0.1:8000/api/admin/dashboard"));
    if (response.statusCode == 200) {
      setState(() {
        dashboardData = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      throw Exception("데이터 불러오기 실패");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("관리자 대시보드")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 📌 상단 카드 3개
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard("총 유저 수",
                          (dashboardData?["total_users"] ?? 0).toString(),
                          Colors.blue),
                      _buildStatCard("오늘 가입",
                          (dashboardData?["new_today"] ?? 0).toString(),
                          Colors.green),
                      _buildStatCard("오늘 문의 수",
                          (dashboardData?["inquiries_today"] ?? 0).toString(),
                          Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 📌 하단 관리 페이지 이동 버튼 3개
                  ElevatedButton(
                    onPressed: () {
                      Get.to(AllInquiryView());
                    },
                    child: Text(
                      "문의 관리 페이지",
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 버스킹 관리 페이지 연결
                      // Get.to(const AllBuskingView());
                    },
                    child: const Text("버스킹 관리 페이지"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 게시판 관리 페이지 연결
                      Get.to(()=> CommunityAdminView());
                    },
                    child: const Text("게시판 관리 페이지"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 3,
      color: color.withOpacity(0.1),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
