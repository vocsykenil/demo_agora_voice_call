
import 'package:agora_uikit/agora_uikit.dart';
import 'package:demo_agora_ui_kit/voiceCall/voice_call_controller.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';


class CallScreen extends StatefulWidget {
  const CallScreen({super.key});
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final VoiceCallController callController = Get.put(VoiceCallController());
  bool muted = false;
  bool speaker = true;

  @override
  void initState() {
    permition();
    super.initState();
  }
void permition ()async{
  print('microphone perrminstion ====> ${await Permission.microphone.status.isGranted}');
  bool isEnable = await callController.agoraEngine.isSpeakerphoneEnabled();
  print('isSpeakerphoneEnabled ====> ${isEnable}');
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Get started with Voice Calling'),
          leading: const SizedBox(),
        ),
        body: Obx(() {
          callController.displayTime = callController.intToTimeLeft(callController.start.value);
          print('call time =========> ${callController.displayTime}');
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              SizedBox(
                  height: 40, child: Center(child: callController.status())),
               SizedBox(height: MediaQuery.sizeOf(context).height * 0.500,),
               Center(
                 child: SizedBox(
                    height: 40,
                    child: Text(callController.displayTime, style: const TextStyle(fontSize: 14),)),
               ),
              const SizedBox(height: 30,),
              // Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  RawMaterialButton(
                    onPressed: _onToggleMute,
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: muted ? Colors.blueAccent : Colors.white,
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      muted ? Icons.mic_off : Icons.mic,
                      color: muted ? Colors.white : Colors.blueAccent,
                      size: 20.0,
                    ),
                  ),
                  RawMaterialButton(
                    onPressed: () => callController.leave(),
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: Colors.redAccent,
                    padding: const EdgeInsets.all(15.0),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 35.0,
                    ),
                  ),
                  RawMaterialButton(
                    onPressed: changeAudioRoute,
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: speaker ? Colors.blueAccent : Colors.white,
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                       Icons.volume_up,
                      color: speaker ? Colors.white : Colors.blueAccent,
                      size: 20.0,
                    ),
                  ),
                ],
              ),
            ],
          );
        }));
  }


  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    callController.agoraEngine.muteLocalAudioStream(muted);
  }




  void changeAudioRoute() {
    setState(() {
      speaker = !speaker;
    });
    callController.agoraEngine.setEnableSpeakerphone(speaker); // Enables or disables the speakerphone temporarily.
  }

}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
showMessage(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
    content: Text(message),
  ));
}
