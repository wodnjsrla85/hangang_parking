import 'package:flutter/material.dart';
import 'package:hangangweb/VM/inquiryHandler.dart';
import 'package:hangangweb/View/Inquiry/all_inquiry_view.dart';
import 'package:hangangweb/View/home.dart';
import 'signup_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final InquiryHandler handler = InquiryHandler();
  final idController = TextEditingController();
  final pwController = TextEditingController();
  //
  bool isLoading = false;

  // 🔐 로그인 함수
  Future<void> login() async {
    // 빈칸 체크
    if (idController.text.isEmpty || pwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('아이디와 비밀번호를 입력하세요'))
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // 로그인 시도
    bool success = await handler.adminLogin(idController.text, pwController.text);

    setState(() {
      isLoading = false;
    });

    if (success) {
      // 로그인 성공 → 문의 목록으로
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 성공!'))
      );
      
      Navigator.pushReplacement(context, 
        MaterialPageRoute(builder: (context) => Home()));
    } else {
      // 로그인 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('아이디 또는 비밀번호가 틀렸습니다'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 그라데이션 배경
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxWidth: 450),
              margin: EdgeInsets.all(20),
              child: Card(
                elevation: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: EdgeInsets.all(40),
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 30),

                      // 제목
                      Text(
                        "관리자 로그인",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d3748),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "계정에 로그인하여 시작하세요",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 40),
                      
                      // 아이디 입력
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: idController,
                          style: TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: '아이디를 입력하세요',
                            prefixIcon: Container(
                              margin: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF667eea)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Color(0xFFF7FAFC),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      
                      // 비밀번호 입력
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: pwController,
                          obscureText: true,
                          style: TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: '비밀번호를 입력하세요',
                            prefixIcon: Container(
                              margin: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF667eea)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.lock, color: Colors.white, size: 20),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Color(0xFFF7FAFC),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                        ),
                      ),
                      SizedBox(height: 35),
                      
                      // 로그인 버튼
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667eea).withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isLoading 
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "로그인",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                      SizedBox(height: 30),
                      
                      // 구분선
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "또는",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      SizedBox(height: 25),
                      
                      // 회원가입 버튼
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF667eea), width: 2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context, 
                              MaterialPageRoute(builder: (context) => SignupView()));
                          },
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            "계정이 없으신가요? 회원가입하기",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF667eea),
                            ),
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
}