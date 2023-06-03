import 'package:adhoc_chat_app/controllers/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Welcome extends StatelessWidget {
  Welcome({super.key});

  AppController _appController = Get.find();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Obx(
          () => ModalProgressHUD(
            inAsyncCall: _appController.showSpinner.value,
            child: Column(
              children: [
                backGroundImage(context),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints.expand(),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.black,
                          Colors.green,
                          Colors.purple,
                          Colors.orange,
                          Colors.orange,
                          Colors.purple,
                          Colors.green,
                          Colors.black,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black12,
                    ),
                    child: Column(
                      children: [
                        welcomeText(),
                        appText(),
                        const Divider(
                          thickness: 1.5,
                          color: Colors.black,
                        ),
                        preparedByText(),
                        creatorsNames(),
                        const Divider(
                          thickness: 1.5,
                          color: Colors.black,
                          endIndent: 30,
                          indent: 30,
                        ),
                        Spacer(),
                        startChattingButton(),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InkWell startChattingButton() {
    return InkWell(
      hoverColor: Colors.red,
      onTap: () {
        _appController.showSpinner.value = true;
        Get.to(
          () => const Chat(),
        );
        _appController.showSpinner.value = false;
        //Go to chat screen and Do nessecary chnages before
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(15.0),
          child: Text(
            "Start Chatting",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Padding creatorsNames() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Text(
          "Ahmed S.Jaber & Hamzah Abu Ali & Mohammed Saeed",
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  Padding preparedByText() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Center(
        child: Text(
          "Prepared by ",
          style: TextStyle(
              color: Colors.black, fontSize: 30, fontWeight: FontWeight.w500),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Text appText() {
    return const Text(
      "Application",
      style: TextStyle(
          color: Colors.purple, fontSize: 30, fontWeight: FontWeight.w500),
    );
  }

  Padding welcomeText() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Center(
        child: Text(
          "Welcome to WIFI-less",
          style: TextStyle(
              color: Colors.purple, fontSize: 30, fontWeight: FontWeight.w500),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  Container backGroundImage(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 300,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            "images/abstract-adult-background-blank.jpg",
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
