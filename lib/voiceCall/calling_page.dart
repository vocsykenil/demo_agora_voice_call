//
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:demo_agora_ui_kit/pages/vedio_call.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:uuid/uuid.dart';
// import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
// class CallScreen extends StatefulWidget {
//   const CallScreen({super.key});
//
//   @override
//   _CallScreenState createState() => _CallScreenState();
// }
// class _CallScreenState extends State<CallScreen> {
//
//   @override
//   void initState() {
//     initRtcEngine();
//     FlutterRingtonePlayer.playRingtone();
//     super.initState();
//   }
//   Future<String?> getAgoraChannelToken(String channel,
//       [String role = "subscriber"]) async {
//     try {
//       String adminUrl = 'https://$appID.webdemo.agora.io/rtc/RtcToken.php?role=1&channelName=${channel}';
//       final Dio dio = Dio();
//       final Response response = await dio.post(
//         adminUrl,
//         data: {"channel": channel, "role": role},
//       );
//       return response.data["token"] as String;
//     } catch (e) {
//       debugPrint("getAgoraChannelToken: $e");
//     }
//     return null;
//   }
//   Future<void> acceptCall() async {
//     FlutterRingtonePlayer.stop();
//     final String? callToken = await getAgoraChannelToken(token);
//     if (callToken == null){
//       // nothing will be done
//       return;
//     }
//     // Create RTC client instance
//     engine = createAgoraRtcEngine();
//     await engine?.initialize( RtcEngineContext(
//         appId: appID
//     ));
//
//     // Define event handler
//     engine?.registerEventHandler(RtcEngineEventHandler(
//       onJoinChannelSuccess: (RtcConnection connection , int elapsed) async {
//         debugPrint('joinChannelSuccess ${connection.channelId} $elapsed');
//         joined = true;
//         startTimer();
//       },
//       onLeaveChannel: (RtcConnection connection, stats) {
//         debugPrint("leaveChannel ${stats.toJson()}");
//         joined = false;
//       },
//       onUserJoined: (RtcConnection connection,int uid, int elapsed) {
//         debugPrint('userJoined $uid');
//         remoteUid = uid;
//         if (playEffect) switchEffect();
//         if (!canIncrement) canIncrement = true;
//       },
//       onUserOffline: (RtcConnection connection,int uid,UserOfflineReasonType userOfflineReasonType) {
//         debugPrint('userOffline $uid');
//         remoteUid = null;
//         canIncrement = false;
//         switchEffect();
//       },
//     ));
//     engine?.enableAudio();
//     engine?.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
//     engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster,);
// // Join channel
//     ChannelMediaOptions options = const ChannelMediaOptions(
//       clientRoleType: ClientRoleType.clientRoleBroadcaster,
//       channelProfile: ChannelProfileType.channelProfileCommunication,
//     );
//
//     await engine?.joinChannel( uid: 0, token:callToken, channelId: token, options: options);
//   }
//    RtcEngine? engine;
//    Timer? _timer;
//   var callListener;
//
//   /// for knowing if the current user joined
//   /// the call channel.
//   bool joined = false;
//   /// the remote user id.
//    int ? remoteUid;
//   /// if microphone is opened.
//   bool openMicrophone = true;
//   /// if the speaker is enabled.
//   bool enableSpeakerphone = true;
//   /// if call sound play effect is playing.
//   bool playEffect = true;
//   /// the call document reference.
//   //  callReference;
//    DocumentReference? callReference;
//   /// call time made.
//   int callTime = 0;
//   /// if the call was accepted
//   /// by the remove user.
//   bool callAccepted = false;
//   /// if callTime can be increment.
//   bool canIncrement = true;
//   void startTimer() {
//     const duration = Duration(seconds: 1);
//     _timer = Timer.periodic(duration, (Timer timer) {
//       if (mounted) {
//         if (canIncrement) {
//           setState((){
//             callTime += 1;
//           });
//         }
//       }
//     });
//   }
//   void switchMicrophone() {
//     engine?.enableLocalAudio(!openMicrophone).then((value) {
//       setState((){
//         openMicrophone = !openMicrophone;
//       });
//     }).catchError((err) {
//       debugPrint("enableLocalAudio: $err");
//     });
//   }
//   void switchSpeakerphone() {
//     engine?.setEnableSpeakerphone(!enableSpeakerphone).then((value) {
//       setState((){
//         enableSpeakerphone = !enableSpeakerphone;
//       });
//     }).catchError((err) {
//       debugPrint("enableSpeakerphone: $err");
//     });
//   }
//
//    Future<void> switchEffect() async {
//      if (playEffect) {
//        engine?.stopEffect(1)?.then((value) {
//          setState((){
//            playEffect = false;
//          });
//        })?.catchError((err) {
//          debugPrint("stopEffect $err");
//        });
//      } else {
//        engine
//            ?.playEffect(
//          soundId: 1, filePath: "assets/sounds/house_phone_uk.mp3", loopCount: 1, pitch: 100, pan: -1, gain: 1,
//        )
//            .then((value) {
//          setState((){
//            playEffect = true;
//          });
//        }).catchError((err) {
//          debugPrint("playEffect $err");
//        });
//      }
//    }
//    Future<void> initRtcEngine() async {
//      final String channelName = const Uuid().v4();
//      // Create RTC client instance
//      engine = createAgoraRtcEngine();
//      await engine?.initialize( RtcEngineContext(
//        appId: appID,
//        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
//      ));
//
//      // engine = await RtcEngine.create(agoraAppId);
//      // Define event handler
//      engine?.registerEventHandler(RtcEngineEventHandler(
//        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
//          debugPrint('joinChannelSuccess ${connection.channelId} $elapsed');
//          if (mounted) {
//            setState((){
//            joined = true;
//          });
//          }
//          // callReference =   engine.(channelName);
//          switchEffect();
//          callListener = FirebaseFirestore.instance.collection("calls").doc(callReference?.id).snapshots().listen((data){
//            if (!data.exists) {
//              Navigator.of(context).pop();
//              return;
//            }
//          });
//        },
//        onLeaveChannel: (RtcConnection connection,stats) {
//          debugPrint("leaveChannel ${stats.toJson()}");
//          if (mounted) {
//            setState((){
//            joined = false;
//          });
//          }
//        },
//        onUserJoined: (RtcConnection connection,int uid, int elapsed) {
//          debugPrint('userJoined $uid');
//          setState((){
//            remoteUid = uid;
//          });
//          // switchEffect();
//          setState((){
//            if (!canIncrement) canIncrement = true;
//            callAccepted = true;
//          });
//          startTimer();
//        },
//        onUserOffline: (RtcConnection connection, int remoteUid,
//            UserOfflineReasonType reason) {
//          debugPrint('userOffline $remoteUid');
//          setState((){
//            remoteUid = 0;
//            canIncrement = false;
//          });
//          switchEffect();
//        },
//      ));
//    }
//
//   @override
//   Widget build(BuildContext context){
//     return Scaffold(
//         appBar: AppBar(
//           title: const Text('Get started with Voice Calling'),
//         ),
//         body: ListView(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//           children: [
//             // Status text
//             Container(
//                 height: 40,
//                 child:Center(
//                     child:_status()
//                 )
//             ),
//             // Button Row
//             Row(
//               children: <Widget>[
//                 Expanded(
//                   child: ElevatedButton(
//                     child: const Text("Join"),
//                     onPressed: () => {join()},
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: ElevatedButton(
//                     child: const Text("Leave"),
//                     onPressed: () => {leave()},
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ));
//   }
//   void  join() async {
//
//     // Set channel options including the client role and channel profile
//     ChannelMediaOptions options = const ChannelMediaOptions(
//       clientRoleType: ClientRoleType.clientRoleBroadcaster,
//       channelProfile: ChannelProfileType.channelProfileCommunication,
//     );
//
//     await engine?.joinChannel(
//       token: token,
//       channelId: token,
//       options: options,
//       uid:,
//     );
//   }
//
//
// }

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

String appID = '7a16834d47be4e0da4b29493f2ed89b2';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // int uid = 0; // uid of the local user

  int? _remoteUid; // uid of the remote user
  bool _isJoined = false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold

  showMessage(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  void initState() {
    super.initState();
    // Set up an instance of Agora engine
    setupVoiceSDKEngine();
  }

  Future<void> setupVoiceSDKEngine() async {
    // retrieve or request microphone permission
    await [Permission.microphone].request();

    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(RtcEngineContext(appId: appID));

    // Register the event handler
    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          showMessage(
              "Local user uid:${connection.localUid} joined the channel");
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          showMessage("Remote user uid:$remoteUid joined the channel");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          showMessage("Remote user uid:$remoteUid left the channel");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );
    agoraEngine.enableAudio();
    await join();
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Get started with Voice Calling'),
          leading: BackButton(
            onPressed: () {
              leave();
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            // Status text
            SizedBox(height: 40, child: Center(child: _status())),
            // Button Row
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    child: const Text("Join"),
                    onPressed: () => {join()},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    child: const Text("Leave"),
                    onPressed: () {
                      setState(() {
                        _isJoined = false;
                        _remoteUid = null;
                      });
                      agoraEngine.leaveChannel();

                    },
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  // Clean up the resources when you leave
  // @override
  // void dispose() async {
  //
  //     super.dispose();
  // }

  void leave() {
    _isJoined = false;
    _remoteUid = null;
    agoraEngine.leaveChannel();
    agoraEngine.release();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    // make sure the call was deleted
    // and you use the callTime for the call logs.
    super.dispose();
  }

  Widget _status() {
    String statusText;

    if (!_isJoined) {
      statusText = 'Join a channel';
    } else if (_remoteUid == null)
      statusText = 'Waiting for a remote user to join...';
    else
      statusText = 'Connected to remote user, uid:$_remoteUid';

    return Text(
      statusText,
    );
  }

  Future join() async {
    FlutterCallkitIncoming.endAllCalls();
    ChannelMediaOptions options = const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    );

    await agoraEngine.joinChannel(
      token:
          '007eJxTYHgZuuGy04yD83WlF3EZ7WY6I+tzf/r3q2XB91+9PxHicdBJgcE80dDMwtgkxcQ8KdUk1SAl0STJyNLE0jjNKDXFwjLJ6Prhq6kNgYwMfVyzmRgZIBDEZ2HIysjPY2AAAN3kIas=',
      channelId: 'jhon',
      options: options,
      uid: 0,
    );
  }

  Future<String?> getAgoraChannelToken(String channel,
      [String role = "subscriber"]) async {
    try {
      String adminUrl =
          'https://$appID.webdemo.agora.io/rtc/RtcToken.php?role=1&channelName=$channel';
      final Dio dio = Dio();
      final response = await dio.post(
        adminUrl,
        data: {"channel": channel, "role": role},
      );
      return response.data["token"] as String;
    } catch (e) {
      debugPrint("getAgoraChannelToken: $e");
    }
    return null;
  }
}
