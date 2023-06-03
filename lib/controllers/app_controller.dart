import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';

class AppController extends GetxController {
  //here all the messages will be saved when each peer send a message
  var Meesages = [Row()].obs;

  //here to track the connection status
  var isConnected = false.obs;

  //here to check the message length
  var messageLengthOk = true.obs;

  //this is used to show progress indicator in case the app is loading something
  var showSpinner = false.obs;
}
