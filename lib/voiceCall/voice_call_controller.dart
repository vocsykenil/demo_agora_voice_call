//
//
// import 'dart:developer';
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../main.dart';
//
//
// class LocalNotification {
//
//   Future<void> setTokenOnFirebase(String token) async {
//     log('uid  =====> ${box.read('uid')}');
//     final data = FirebaseFirestore.instance
//         .collection('token')
//         .doc(box.read('uid'));
//       await data.get().then((value) {
//         if (value.exists) {
//           data.update({'token': token});
//         }else {
//           data.set({'token': token});
//         }
//       });
//   }
//
//   Future<String> getToken(String userId) async {
//     Map<String, dynamic> data1 = {};
//     final data = FirebaseFirestore.instance.collection('token').doc(userId);
//     await data.get().then((value) {
//       data1 = value.data() as Map<String, dynamic>;
//     });
//     return data1['token'];
//   }
//
//   Future<void> setDeviceInfo () async {
//     final data = FirebaseFirestore.instance
//         .collection('users')
//         .doc(box.read('uid'));
//     await data.get().then((value) {
//
//       if (value.exists) {
//         data.update({'device': Platform.isAndroid?'android':'ios'});
//       }else {
//         data.set({'device': Platform.isAndroid?'android':'ios'});
//       }
//     });
//   }
// }

import 'dart:async';
import 'package:demo_agora_ui_kit/vedio_call/vedio_call.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';

import 'calling_page.dart';

class VoiceCallController extends GetxController {

  late CallKitParams callKitParams;
  RxInt start = 0.obs;
   Timer? timer ;
  String displayTime = '';
  RxInt? remoteUidForUser; // uid of the remote user
  RxBool isJoined = false.obs; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance
  Future<void> setupVoiceSDKEngine() async {
    // retrieve or request microphone permission
    await [Permission.microphone].request();
    await [Permission.audio].request();
    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(RtcEngineContext(
      appId: appID,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          showMessage(
              "Local user uid:${connection.localUid} joined the channel");
          isJoined.value = true;
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          showMessage("Remote user uid:$remoteUid joined the channel");
          print('================ call connected ================');
          startCallTimer();
          remoteUidForUser?.value = remoteUid;
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          showMessage("Remote user uid:$remoteUid left the channel");
          remoteUidForUser = null;
          leave();
        },
      ),
    );
    agoraEngine.enableAudio();
  }

  Future<void> leave() async {
    print('jay hanuman dada ===============>');
    isJoined.value = false;
    remoteUidForUser = null;
    timer?.cancel();
    start.value = 0;
    agoraEngine.leaveChannel();

    // agoraEngine.release();
    FlutterCallkitIncoming.endAllCalls();
    Get.back();
  }


  Widget status() {
    RxString statusText = ''.obs;

    if (!isJoined.value) {
      statusText.value = 'Join a channel';
    } else if (remoteUidForUser == null)
      statusText.value = 'Waiting for a remote user to join...';
    else
      statusText.value = 'Connected to remote user, uid:$remoteUidForUser';

    return Obx(() {
      return Text(
        statusText.value,
      );
    });
  }

  Future join(String channelNAme) async {
    ChannelMediaOptions options = const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    );
    String token = await generateToken(channelNAme);
    print('channel name =========> $channelNAme');
    print('token =========> $token');
      await agoraEngine.joinChannel(
        token: token,
        channelId: channelNAme,
        options: options,
        uid: 0,
      );
  }

  String intToTimeLeft() {
    int h, m, s;
    h = start.value ~/ 3600;
    m = ((start.value - h * 3600)) ~/ 60;
    s = start.value - (h * 3600) - (m * 60);
    String hourLeft = h.toString().length < 2 ? '0$h' : h.toString();
    String minuteLeft = m.toString().length < 2 ? '0$m' : m.toString();
    String secondsLeft = s.toString().length < 2 ? '0$s' : s.toString();
    String result = "$hourLeft:$minuteLeft:$secondsLeft";
    return result;
  }

  void startCallTimer() {
   final startTime = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final duration = now.difference(startTime).inSeconds;
      print('Call duration: $duration seconds');
      start.value = duration;
    });
  }
}
