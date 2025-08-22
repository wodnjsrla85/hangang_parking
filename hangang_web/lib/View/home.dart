import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hangangweb/View/Inquiry/all_inquiry_view.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Get.to(AllInquiryView());
              }, 
              child: Text("문의 관리 페이지로 이동")
            ),
            // 버스킹 관리 페이지이동
            // 게시판 관리 페이지이동
          ],
        ),
      ),
    );
  }
}