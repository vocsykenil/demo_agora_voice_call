import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_agora_ui_kit/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:http/http.dart' as https;
import 'package:uuid/uuid.dart';

import '../home_page.dart';

String appID = '7a16834d47be4e0da4b29493f2ed89b2';
// String appCertificate = '058aed4edb5642699c16911982c343c7';

class VideoCallPage extends StatefulWidget {
  final String channelName;
  final Map<String,dynamic>? data;
  final bool isSelfCut;

  const VideoCallPage({
    Key? key,
    required this.channelName,
    required this.data,required this.isSelfCut
  }) : super(key: key);

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  Stopwatch stopwatch = Stopwatch();

  // int? _remoteUid;
  // bool _localUserJoined = false;
  late RxBool isCall;

  bool muted = false;

  @override
  void initState() {

    isCall = true.obs;
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelName)
        .get()
        .then((value) {
      value.data()?["isCall"] == true ? callQuery() : null;
    });
    initCall();
    super.initState();
    // initAgora();
  }
  Future<void> callQuery() async {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelName)
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
  Future<void> initCall() async {
    await [Permission.microphone, Permission.camera].request();
    await callController.agoraEngine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster);
    await callController.agoraEngine.enableVideo();
    await callController.agoraEngine.startPreview();
    String token = await generateToken(widget.channelName);
    await callController.agoraEngine.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  // Future<void> initAgora() async {
  //   // retrieve permissions
  //
  //
  //   //create the engine
  //   _engine = createAgoraRtcEngine();
  //   await _engine.initialize(RtcEngineContext(
  //     appId: appID,
  //     channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
  //   ));
  //
  //   _engine.registerEventHandler(
  //     RtcEngineEventHandler(
  //       onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  //         debugPrint("local user ${connection.localUid} joined");
  //         setState(() {
  //           _localUserJoined = true;
  //         });
  //       },
  //       onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
  //         debugPrint("remote user $remoteUid joined");
  //         setState(() {
  //           stopwatch.start();
  //           _remoteUid = remoteUid;
  //         });
  //       },
  //       onUserOffline: (RtcConnection connection, int remoteUid,
  //           UserOfflineReasonType reason) {
  //         debugPrint("remote user $remoteUid left channel");
  //         setState(() {
  //           _remoteUid = null;
  //         });
  //       },
  //       onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
  //         debugPrint(
  //             '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
  //       },
  //     ),
  //   );
  //

  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Video Call'),
      ),
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 150,
              // child: Center(
              //   child: _localUserJoined
              //       ? AgoraVideoView(
              //           controller: VideoViewController(
              //               rtcEngine: _engine,
              //               canvas: const VideoCanvas(uid: 0),
              //               useFlutterTexture: true),
              //         )
              //       : const CircularProgressIndicator(),
              // ),
              child: Obx(() {
                return Center(
                  child: callController.isJoined.value
                      ? AgoraVideoView(
                    controller: VideoViewController(
                        rtcEngine: callController.agoraEngine,
                        canvas: const VideoCanvas(uid: 0),
                        useFlutterTexture: true),
                  )
                      : const CircularProgressIndicator(),
                );
              }),
            ),
          ),
          Positioned(
            bottom: 70,
            left: 0.000001,
            right: 0.000001,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RawMaterialButton(
                  onPressed: null,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.blueAccent,
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                      '${stopwatch.elapsed.inMinutes}:${stopwatch.elapsed
                          .inSeconds}'),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0.000001,
            right: 0.000001,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  // onPressed: () => _onCallEnd(context),
                  onPressed: () {

                      if (widget.isSelfCut == true) {
                        callController.leave();
                        if (widget.data?['device'] == 'android') {
                          sendMessage(
                            token: widget.data?['token'],
                            data: {
                              "senderName": widget.data?['email'],
                              "avatar": '',
                              "UserId": widget.data?['uid'],
                              "senderId": box.read('uid'),
                              "isVoiceCall":"0",
                              "type": 'Cut',
                              "channelName": '${box.read('uid')}_${widget
                                  .data?['uid']}',
                              "id": 0,
                              "sound": "default",
                            },
                          );
                        } else {
                          sendIosCallNotification(
                              deviceToken: widget.data?['token'],
                              senderName: widget.data?['device'],
                              channelName: '${box.read('uid')}_${widget
                                  .data?['uid']}',
                              avatar: "",
                              isVoiceCall: '0',
                              userId: widget.data?['uid'],
                              senderId: box.read("uid"),
                              type: "Cut",
                              uuid: const Uuid().v4());
                        }
                      } else {
                        callController.leave();
                      }
                    },
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
                  onPressed: _onSwitchCamera,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: const Icon(
                    Icons.switch_camera,
                    color: Colors.blueAccent,
                    size: 20.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    callController.agoraEngine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    callController.agoraEngine.switchCamera();
  }

  Future<void> _onCallEnd(BuildContext context) async {
    stopwatch.stop();
    await callController.agoraEngine.leaveChannel();
    await FlutterCallkitIncoming.endAllCalls();
    Navigator.pop(context);
  }

  // Display remote user's video
  Widget _remoteVideo() {
    return StreamBuilder<int>(
        stream: callController.remoteUidForUser.stream,
        builder: (context, snapshot) {
          print('callController.remoteUidForUser =========> ${snapshot.data}');
          if (snapshot.hasData && snapshot.data != 0) {
            return AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: callController.agoraEngine,
                canvas:  VideoCanvas(
                    uid:snapshot.data),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            );
          } else {
            return const Text(
              'Please wait for remote user to join',
              textAlign: TextAlign.center,
            );
          }
        }
    );
  }
}

Future<String> generateToken(String channelName) async {
  String uri =
      'https://agora-token-generator-demo.vercel.app/api/main?type=rtc';
  Map<String, dynamic> body = {
    "appId": "7a16834d47be4e0da4b29493f2ed89b2",
    "certificate": "058aed4edb5642699c16911982c343c7",
    "channel": channelName,
    "uid": "0",
    "role": "publisher",
    "expire": 3600
  };
  String jsonBody = json.encode(body);
  Map<String, String> headers = {"Content-Type": "application/json"};
  final response =
  await https.post(Uri.parse(uri), body: jsonBody, headers: headers);
  final decodeData = jsonDecode(response.body);
  return decodeData['rtcToken'];
}