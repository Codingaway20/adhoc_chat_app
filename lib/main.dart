import 'package:adhoc_chat_app/controllers/app_controller.dart';
import 'package:adhoc_chat_app/welcome.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AppController());
    return  GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Welcome(),
    );
  }
}
