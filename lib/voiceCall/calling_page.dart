import 'package:agora_uikit/agora_uikit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_agora_ui_kit/voiceCall/voice_call_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../home_page.dart';
import '../main.dart';

class CallScreen extends StatefulWidget {
  final String chanelName;
  final Map<String,dynamic>? data;
  final bool isSelfCut;

  const CallScreen({super.key, required this.chanelName,required this.data,required this.isSelfCut});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final VoiceCallController callController = Get.put(VoiceCallController());
  bool muted = false;
  late RxBool isCall;
  bool speaker = true;

  @override
  void initState() {
    isCall = true.obs;
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.chanelName)
        .get()
        .then((value) {
      value.data()?["isCall"] == true ? callQuery() : null;
    });
    super.initState();
  }

  Future<void> callQuery() async {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.chanelName)
        .snapshots()
        .listen((event) async {
      print('is call ============> ${event.data()?["isCall"]}');
      // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (event.data()?["isCall"] == false && isCall.value == true) {
          print('hello how are ==========> ');
          if(mounted){
            setState(() {
              isCall.value = false;
              callController.leave();
            });
          }

        }
      // });
    });
  }

  void permition() async {
    print(
        'microphone perrminstion ====> ${await Permission.microphone.status.isGranted}');
    bool isEnable = await callController.agoraEngine.isSpeakerphoneEnabled();
    print('isSpeakerphoneEnabled ====> $isEnable');
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: const Text('Get started with Voice Calling'),
          leading: const SizedBox(),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            SizedBox(height: 40, child: Center(child: callController.status())),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.500,
            ),
            Obx(() {
              callController.displayTime =
                  callController.intToTimeLeft(callController.start.value);
              return Center(
                child: SizedBox(
                    height: 40,
                    child: Text(
                      callController.displayTime,
                      style: const TextStyle(fontSize: 14),
                    )),
              );
            }),
            const SizedBox(
              height: 30,
            ),

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
                  // onPressed: () => ,
                  onPressed: () {if(widget.isSelfCut == true){
                    callController.leave();
                    if (widget.data?['device'] == 'android') {
                      sendMessage(
                        token: widget.data?['token'],
                        data: {
                          "senderName": widget.data?['email'],
                          "avatar": '',
                          "UserId": widget.data?['uid'],
                          "senderId": box.read('uid'),
                          "type": 'Cut',
                          "channelName": '${box.read('uid')}_${widget.data?['uid']}',
                          "id": 0,
                          "sound": "default",
                        },
                      );
                    } else {
                      sendIosCallNotification(
                          deviceToken: widget.data?['token'],
                          senderName: widget.data?['device'],
                          channelName: '${box.read('uid')}_${widget.data?['uid']}',
                          avatar: "",
                          isVoiceCall: '1',
                          userId: widget.data?['uid'],
                          senderId: box.read("uid"),
                          type: "Cut",
                          uuid: const Uuid().v4());
                    }
                  }else{
                    callController.leave();
                  }

                  },
                  // onPressed: () {
                  //   final call = FirebaseFirestore.instance.collection('calls');
                  //   call.doc(widget.chanelName).get().then((value) {
                  //     if (value.exists) {
                  //       call.doc(widget.chanelName).update({"isCall": false});
                  //     } else {
                  //       call.doc(widget.chanelName).set({"isCall": false});
                  //     }
                  //   });
                  //   setState(() {});
                  // },
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
            )
          ],
        ));
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
    callController.agoraEngine.setEnableSpeakerphone(
        speaker); // Enables or disables the speakerphone temporarily.
  }

}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
showMessage(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
    content: Text(message),
  ));
}
