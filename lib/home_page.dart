import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_agora_ui_kit/vedio_call/vedio_call.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:loader_overlay/loader_overlay.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import 'main.dart';
import 'voiceCall/calling_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  late final Uuid _uuid;
  String? _currentUuid;
  String textEvents = "";

  @override
  void initState() {
    super.initState();
    _uuid = const Uuid();
    _currentUuid = "";
    textEvents = "";
    // initCurrentCall();
    listenerEvent(onEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home page'),
        leading: const SizedBox(),
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('users').get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                itemCount: snapshot.data?.docChanges.length,
                itemBuilder: (context, index) {
                  return snapshot.data!.docChanges[index].doc['uid'] !=
                          box.read('uid')
                      ? ListTile(
                          title: Text(
                              snapshot.data!.docChanges[index].doc['email']),
                          trailing: SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.call,
                                    color: Colors.green,
                                  ),
                                  onPressed: () async {
                                    Map<String, dynamic> data = {
                                      "token": snapshot
                                          .data!.docChanges[index].doc['token'],
                                      'uid': snapshot
                                          .data!.docChanges[index].doc['uid'],
                                      "email":box.read('uid') == snapshot.data!.docChanges[index].doc['uid']?  snapshot
                                          .data!.docChanges[index].doc['email']:"unknown",
                                      'device': snapshot
                                          .data!.docChanges[index].doc['device']
                                    };
                                    startOutGoingCall(
                                      snapshot
                                          .data!.docChanges[index].doc['token'],
                                      snapshot
                                          .data!.docChanges[index].doc['uid'],
                                      box.read('uid') == snapshot.data!.docChanges[index].doc['uid']?  snapshot
                                        .data!.docChanges[index].doc['email']:"unknown",
                                      snapshot.data!.docChanges[index]
                                          .doc['device'],
                                      true,
                                      data,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.video_call,
                                    color: Colors.green,
                                  ),
                                  onPressed: () async {
                                    Map<String, dynamic> data = {
                                      "token": snapshot
                                          .data!.docChanges[index].doc['token'],
                                      'uid': snapshot
                                          .data!.docChanges[index].doc['uid'],
                                      "email":box.read('uid') == snapshot.data!.docChanges[index].doc['uid']?  snapshot
                                          .data!.docChanges[index].doc['email']:"unknown",
                                      'device': snapshot
                                          .data!.docChanges[index].doc['device'],
                                    };
                                    startOutGoingCall(
                                      snapshot.data!.docChanges[index].doc['token'],
                                      snapshot.data!.docChanges[index].doc['uid'],
                                      box.read('uid') == snapshot.data!.docChanges[index].doc['uid']?  snapshot
                                          .data!.docChanges[index].doc['email']:"unknown",
                                      snapshot.data!.docChanges[index]
                                          .doc['device'], false, data,);
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox();
                },
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }

  Future<dynamic> initCurrentCall() async {
    //check current call from pushkit if possible
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        print('DATA 0000: $calls');
        _currentUuid = calls[0]['id'];
        return calls[0];
      } else {
        _currentUuid = "";
        return null;
      }
    }
  }

  Future<void> endCurrentCall() async {
    initCurrentCall();
    await FlutterCallkitIncoming.endCall(_currentUuid!);
  }

  void startOutGoingCall(String token, String userID, String name,
      String device, bool isVoiceCall, Map<String, dynamic> data) {
    context.loaderOverlay.show();
    final call = FirebaseFirestore.instance.collection('calls');
    call.doc('${box.read('uid')}_$userID').get().then((value) {
      if (value.exists) {
        call.doc('${box.read('uid')}_$userID').update({"isCall": true});
      } else {
        call.doc('${box.read('uid')}_$userID').set({"isCall": true});
      }
    });
    Future.delayed(const Duration(seconds: 3), () async {
      if (device == 'android') {
        sendMessage(
          token: token,
          data: {
            "senderName": name,
            "avatar": '',
            "UserId": userID,
            "senderId": box.read('uid'),
            "type": 'is Calling you',
            "isVoiceCall": isVoiceCall == true ? 0.toString() : 1.toString(),
            "channelName": '${box.read('uid')}_$userID',
            "id": 0,
            "sound": "default",
          },
        );
      } else {
        sendIosCallNotification(
            deviceToken: token,
            senderName: name,
            channelName: '${box.read('uid')}_$userID',
            avatar: "",
            isVoiceCall: isVoiceCall == true ? 0.toString() : 1.toString(),
            userId: userID,
            senderId: box.read("uid"),
            type: "is Calling you",
            uuid: const Uuid().v4());
      }

      _currentUuid = _uuid.v4();
      final params = CallKitParams(
        id: _currentUuid,
        nameCaller: name,
        handle: '0123456789',
        type: isVoiceCall == true ? 0 : 1,
        extra: data,
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: true,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: 'assets/test.png',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
        ),
        ios: const IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'number',
          supportsVideo: true,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: true,
          supportsHolding: true,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      await FlutterCallkitIncoming.startCall(params);
      callController.join('${box.read('uid')}_$userID');
      if (isVoiceCall == true) {

        context.loaderOverlay.hide();
        Get.to(() => CallScreen(
              chanelName: '${box.read('uid')}_$userID',
              data: params.extra,
              isSelfCut: true,
            ));
      } else {
        context.loaderOverlay.hide();
        Get.to(() => VideoCallPage(channelName: '${box.read('uid')}_$userID', data: params.extra,isSelfCut: true,));
      }
    });
  }

  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }

  Future<void> listenerEvent(void Function(CallEvent) callback) async {
    try {
      FlutterCallkitIncoming.onEvent.listen((event) async {
        print('HOME: $event');
        switch (event!.event) {
          case Event.actionCallIncoming:
            // TODO: received an incoming call
            break;
          case Event.actionCallStart:
            // TODO: started an outgoing call
            // TODO: show screen calling in Flutter
            break;
          case Event.actionCallAccept:
            // callController.setupVoiceSDKEngine();
            callController.join(event.body['extra']['channelName']);
            if (event.body['type'] == 0) {
              // callController.join(]);
              Get.to(() => CallScreen(
                    chanelName: event.body['extra']['channelName'],
                    isSelfCut: false,
                    data: {},
                  ));
            } else {
              Get.to(() => VideoCallPage(
                isSelfCut: false,
                  data: {},
                  channelName: event.body['extra']['channelName']));
            }

            break;
          case Event.actionCallDecline:
            // TODO: declined an incoming call

            print('====================> action Call Decline <================');
            final call = FirebaseFirestore.instance.collection('calls');
            call.doc(event.body['extra']['channelName']).get().then((value) {
              if (value.exists) {
                call
                    .doc(event.body['extra']['channelName'])
                    .update({"isCall": false});
              }
            });
            callController.leave();
            // endAllCalls();
            await requestHttp("ACTION_CALL_DECLINE_FROM_DART");
            break;
          case Event.actionCallEnded:
            print('====================> action Call Ended <================');
            final call = FirebaseFirestore.instance.collection('calls');
            call.doc(event.body['extra']['channelName']).get().then((value) {
              if (value.exists) {
                call
                    .doc(event.body['extra']['channelName'])
                    .update({"isCall": false});
              }
            });
            callController.leave();
            // TODO: ended an incoming/outgoing call
            break;
          case Event.actionCallTimeout:
            print('hello how are ===============>');
            final call = FirebaseFirestore.instance.collection('calls');
            call.doc(event.body['extra']['channelName']).get().then((value) {
              if (value.exists) {
                call
                    .doc(event.body['extra']['channelName'])
                    .update({"isCall": false});
              }
            });
            // TODO: missed an incoming call
            break;
          case Event.actionCallCallback:
            // TODO: only Android - click action `Call back` from missed call notification
            break;
          case Event.actionCallToggleHold:
            // TODO: only iOS
            break;
          case Event.actionCallToggleMute:
            // TODO: only iOS
            break;
          case Event.actionCallToggleDmtf:
            // TODO: only iOS
            break;
          case Event.actionCallToggleGroup:
            // TODO: only iOS
            break;
          case Event.actionCallToggleAudioSession:
            // TODO: only iOS
            break;
          case Event.actionDidUpdateDevicePushTokenVoip:
            // TODO: only iOS
            break;
          case Event.actionCallCustom:
            break;
        }
        callback(event);
      });
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<void> requestHttp(content) async {
    get(Uri.parse(
        'https://webhook.site/2748bc41-8599-4093-b8ad-93fd328f1cd2?data=$content'));
  }

  void onEvent(CallEvent event) {
    if (!mounted) return;
    setState(() {
      textEvents += '${event.toString()}\n';

      print('========================> $textEvents');
    });
  }

  void get(Uri parse) {}
}

Future sendMessage({
  required String token,
  required Map<String, dynamic> data,
}) async {
  Map data0 = {
    "data": data,
    "content_available": true,
    "ios_voip": 1,
    "priority": "high",
    "to": token,
  };
  final dio = Dio();
  try {
    final response = await dio.post(
      'https://fcm.googleapis.com/fcm/send',
      data: data0,
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json',
          "apns-push-type": "background",
          'Authorization':
              'key=AAAAdZ5yjas:APA91bGXmOAZkpJw0-G_nwtUaanY--56OKU7IhJ5qMG1ErLNwwktkqoNwQ9h0HCRzP1pbhcLjZ-vmigpeGRuUY_PuKsu9LwERHKTzviFW-DW1oCfPrVyFmg4stspRUMTqiR543iNr5hj'
        },
      ),
    );

    if (response.statusCode == 200) {
      log('response daya :: ${response.data}');

      log("Yeh notificatin is sended");
    } else {
      log("Error");
    }
  } catch (e) {
    log('notification error ---> $e');
  }
}

Future sendIosCallNotification(
    {required String deviceToken,
    required String senderName,
    required String avatar,
    required String userId,
    required String channelName,
    required String isVoiceCall,
    required String senderId,
    required String type,
    required String uuid}) async {
  print('Hello sendIosCallNotification');
  Map data = {
    "device_token": deviceToken,
    "alert": senderName,
    "nameCaller": senderName,
    "senderName": senderName,
    "isVoiceCall": isVoiceCall,
    "avatar": avatar,
    "UserId": userId,
    "channelName": channelName,
    "senderId": senderId,
    "type": type,
    "id": uuid,
    "handle": "0123456789"
  };
  // var body = json.encode(data);
  Map<String, String>? headers = {
    "Content-Type": "application/x-www-form-urlencoded",
  };
  http.Response res = await http.post(
    Uri.parse('https://vocsyapp.com/DemoCall_API/sendbox.php'),
    headers: headers,
    body: data,
    encoding: Encoding.getByName('utf-8'),
  );
  print('Hello sendCallNotification com ${res.body}');
}

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      width: MediaQuery.sizeOf(context).width,
      child: Center(
        child: SizedBox(
            height: 150,
            width: 150,
            child:
                Lottie.asset("assets/files/call_Animation.json", repeat: true)),
      ),
    );
  }
}
