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
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';

import 'calling_page.dart';

class CallController extends GetxController{

  RxInt? _remoteUid; // uid of the remote user
  bool _isJoined = false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance
  Future<void> setupVoiceSDKEngine(String channelName) async {
    // retrieve or request microphone permission
    await [Permission.microphone].request();
    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(RtcEngineContext(
      appId: appID,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // Register the event handler
    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          showMessage(
              "Local user uid:${connection.localUid} joined the channel");

            _isJoined = true;
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          showMessage("Remote user uid:$remoteUid joined the channel");

            _remoteUid?.value = remoteUid;

        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          showMessage("Remote user uid:$remoteUid left the channel");

            _remoteUid = null;
            leave();

        },
      ),
    );
    agoraEngine.enableAudio();
    await join(channelName);
  }


  void leave() {
    _isJoined = false;
    _remoteUid = null;
    FlutterCallkitIncoming.endAllCalls();
    agoraEngine.leaveChannel();
    agoraEngine.release();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
   Get.back();
    });
  }

  @override
  void dispose() {
    // make sure the call was deleted
    // and you use the callTime for the call logs.
    super.dispose();
  }

  Widget status() {
    RxString statusText = ''.obs;

    if (!_isJoined) {
      statusText.value = 'Join a channel';
    } else if (_remoteUid == null)
      statusText.value = 'Waiting for a remote user to join...';
    else
      statusText.value = 'Connected to remote user, uid:$_remoteUid';

    return Text(
      statusText.value,
    );
  }

  Future join(String channelNAme ) async {
    ChannelMediaOptions options = const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    );
    String token = await generateToken(channelNAme);
    print('channel name =========> ${channelNAme}');
    print('token =========> $token');
    await agoraEngine.joinChannel(
      token: token,
      // '007eJxTYFBJn3I65r3zuR+VVysfmE49YPhboSnz/PXHmqdrX27c8+qJAoN5oqGZhbFJiol5UqpJqkFKokmSkaWJpXGaUWqKhWWS0ZQv11IbAhkZVpjtYGZkgEAQ35Ih1zc/KdQ4L6QwPCU4Mc8kMjQgKCo11cXI2y3bKN7Y38iyyLLKMT0rKTM8tSgit6SqKMrD0CAvx8yIgQEAPvk2YA==',
      channelId: channelNAme,
      options: options,
      uid: 0,
    );
  }
}