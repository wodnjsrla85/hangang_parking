import 'package:flutter/material.dart';
import 'package:get/get.dart'; // ✅ GetX import
import 'package:hangangweb/VM/inquiryHandler.dart';
import 'login_view.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final InquiryHandler handler = InquiryHandler();
  final idController = TextEditingController();
  final pwController = TextEditingController();
  final pwConfirmController = TextEditingController();

  bool isLoading = false;

  // 🔐 회원가입 함수
  Future<void> signup() async {
    if (idController.text.isEmpty ||
        pwController.text.isEmpty ||
        pwConfirmController.text.isEmpty) {
      Get.snackbar("입력 오류", "모든 항목을 입력하세요",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (pwController.text != pwConfirmController.text) {
      Get.snackbar("비밀번호 오류", "비밀번호가 일치하지 않습니다",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    if (idController.text.length < 3) {
      Get.snackbar("아이디 오류", "아이디는 3자 이상 입력하세요",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    if (pwController.text.length < 4) {
      Get.snackbar("비밀번호 오류", "비밀번호는 4자 이상 입력하세요",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    setState(() {
      isLoading = true;
    });

    String result =
        await handler.adminSignup(idController.text, pwController.text);

    setState(() {
      isLoading = false;
    });

    if (result == 'success') {
      Get.snackbar("성공", "회원가입 성공! 로그인해주세요",
          snackPosition: SnackPosition.BOTTOM);
      // ✅ Navigator → GetX 라우팅으로 교체
      Get.offAll(() =>  LoginView());
    } else {
      Get.snackbar("실패", "회원가입 실패: $result",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 그라데이션 배경
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              margin: const EdgeInsets.all(20),
              child: Card(
                elevation: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 로고/아이콘
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF10b981), Color(0xFF059669)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add,
                            size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 30),

                      const Text(
                        "관리자 회원가입",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d3748),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("새로운 관리자 계정을 만드세요",
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 40),

                      // 아이디 입력
                      _buildTextField(
                        controller: idController,
                        hint: "아이디 (3자 이상)",
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 25),

                      // 비밀번호 입력
                      _buildTextField(
                        controller: pwController,
                        hint: "비밀번호 (4자 이상)",
                        icon: Icons.lock,
                        obscure: true,
                      ),
                      const SizedBox(height: 25),

                      // 비밀번호 확인 입력
                      _buildTextField(
                        controller: pwConfirmController,
                        hint: "비밀번호 확인",
                        icon: Icons.lock_outline,
                        obscure: true,
                      ),
                      const SizedBox(height: 35),

                      // 회원가입 버튼
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF10b981), Color(0xFF059669)]),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "회원가입",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 구분선
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("또는",
                                style: TextStyle(color: Colors.grey[600])),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // 로그인 페이지로 이동 버튼
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF10b981)),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextButton(
                          onPressed: () {
                            // ✅ Navigator → GetX 라우팅으로 교체
                            Get.offAll(() => LoginView());
                          },
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "이미 계정이 있으신가요? 로그인하기",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10b981)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 📌 중복 줄이기 위해 TextField 빌더 메서드
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF10b981), Color(0xFF059669)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF7FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
