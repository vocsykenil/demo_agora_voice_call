import 'package:demo_agora_ui_kit/voiceCall/voice_call_controller.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';


class CallScreen extends StatelessWidget {
   CallScreen({super.key});
  final CallController callController = Get.put(CallController());

  // Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Get started with Voice Calling'),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            // Status text
            Obx(() {
              return SizedBox(
                  height: 40, child: Center(child: callController.status()));
            }),
            const SizedBox(height: 30,),
            // Button Row
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    child: const Icon(
                      Icons.call_end, size: 30, color: Colors.red,),
                    onPressed: () => {callController.leave()},
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ));
  }
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
showMessage(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
    content: Text(message),
  ));
}
