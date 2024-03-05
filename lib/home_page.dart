import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_agora_ui_kit/voiceCall/voice_call_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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
    initCurrentCall();
    listenerEvent(onEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home page'),
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
                                    startOutGoingCall(
                                        snapshot.data!.docChanges[index].doc['token'],
                                        snapshot.data!.docChanges[index].doc['uid'],
                                        snapshot.data!.docChanges[index].doc['email'],
                                        snapshot.data!.docChanges[index].doc['device'],true);
                                  },
                                ),
                                // IconButton(
                                //   icon: const Icon(
                                //     Icons.video_call,
                                //     color: Colors.green,
                                //   ),
                                //   onPressed: () async {
                                //     startOutGoingCall(
                                //         snapshot.data!.docChanges[index].doc['token'],
                                //         snapshot.data!.docChanges[index].doc['uid'],
                                //         snapshot.data!.docChanges[index].doc['email'],
                                //         snapshot.data!.docChanges[index].doc['device'],false);
                                //   },
                                // ),
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

  Future startOutGoingCall(
      String token, String userID, String name, String device,bool isVoiceCall) async {
    if (device == 'android') {
      sendMessage(
        token: token,
        data: {
          "senderName": name,
          "avatar": '',
          "UserId": userID,
          "senderId": box.read('uid'),
          "type": '1',
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
          isVoiceCall: isVoiceCall == true ? 1.toString():0.toString(),
          userId: userID,
          senderId: box.read("uid"),
          type: "call",
          uuid: const Uuid().v4());
    }

    _currentUuid = _uuid.v4();
    final params = CallKitParams(
      id: _currentUuid,
      nameCaller: 'akash kachhi',
      handle: '0123456789',
      type: 1,
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
      android: const AndroidParams(
        isCustomNotification: false,
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
    print('user id =====> $userID');
    print('user id 00 =====> ${box.read('uid')}');
    print('user id 11 =====> $name');
    print('user id 22 =====> ${box.read('uid')}_$userID');
    VoiceCallController callController = Get.put(VoiceCallController());
      callController.setupVoiceSDKEngine();
      callController.join('${box.read('uid')}_$userID');
      Get.to(() =>  const CallScreen());
  }

  // Future<void> activeCalls() async {
  //   var calls = await FlutterCallkitIncoming.activeCalls();
  // }

  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }

  Future<void> getDevicePushTokenVoIP() async {
    var devicePushTokenVoIP =
        await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    print(devicePushTokenVoIP);
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
            VoiceCallController callController = Get.put(VoiceCallController());
            callController.setupVoiceSDKEngine();
            callController.join(event.body['extra']['channelName'].toString());

            Get.to(() =>  CallScreen());
            break;
          case Event.actionCallDecline:
            // TODO: declined an incoming call
            endAllCalls();
            await requestHttp("ACTION_CALL_DECLINE_FROM_DART");
            break;
          case Event.actionCallEnded:
            // TODO: ended an incoming/outgoing call
            break;
          case Event.actionCallTimeout:
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

  Future<void> requestHttp(content) async {
    get(Uri.parse(
        'https://webhook.site/2748bc41-8599-4093-b8ad-93fd328f1cd2?data=$content'));
  }

  void onEvent(CallEvent event) {
    if (!mounted) return;
    setState(() {
      textEvents += '${event.toString()}\n';

      print('========================> ${textEvents}');
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
