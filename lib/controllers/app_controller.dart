import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';

class AppController extends GetxController {
  var Meesages = [Row()].obs;

  var isConnected = false.obs;
  var messageLengthOk = true.obs;

  var showSpinner = false.obs;
}
