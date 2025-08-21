import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hangangweb/View/all_inquiry_view.dart';
import 'package:hangangweb/View/answer_inquiry.dart';
import 'package:hangangweb/View/login_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
