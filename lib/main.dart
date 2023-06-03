import 'package:adhoc_chat_app/controllers/app_controller.dart';
import 'package:adhoc_chat_app/welcome.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//main function
void main() {
  runApp(const MyApp());
}

//main class
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AppController());
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Welcome(), //=> First screen you see
    );
  }
}
