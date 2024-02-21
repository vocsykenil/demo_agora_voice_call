import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';

import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';

import 'package:uuid/uuid.dart';

import 'calling_page.dart';


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
        title: const Text('Plugin example app'),
        actions: <Widget>[

          IconButton(
            icon: const Icon(
              Icons.call,
              color: Colors.green,
            ),
            onPressed: startOutGoingCall,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          if (textEvents.isNotEmpty) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Text(textEvents),
              ),
            );
          } else {
            return const Center(
              child: Text('No Event'),
            );
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
        print('DATA: $calls');
        _currentUuid = calls[0]['id'];
        return calls[0];
      } else {
        _currentUuid = "";
        return null;
      }
    }
  }

  // Future<void> makeFakeCallInComing() async {
  //   await Future.delayed(const Duration(seconds: 10), () async {
  //     _currentUuid = _uuid.v4();
  //
  //     final params = CallKitParams(
  //       id: _currentUuid,
  //       nameCaller: 'Hien Nguyen',
  //       appName: 'Callkit',
  //       avatar: 'https://i.pravatar.cc/100',
  //       handle: '0123456789',
  //       type: 1,
  //       duration: 10000,
  //       textAccept: 'Accept',
  //       textDecline: 'Decline',
  //       missedCallNotification: const NotificationParams(
  //         showNotification: true,
  //         isShowCallback: true,
  //         subtitle: 'Missed call',
  //         callbackText: 'Call back',
  //       ),
  //       extra: <String, dynamic>{'userId': '1a2b3c4d'},
  //       headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
  //       android: const AndroidParams(
  //         isCustomNotification: true,
  //         isShowLogo: false,
  //         ringtonePath: 'system_ringtone_default',
  //         backgroundColor: '#0955fa',
  //         backgroundUrl: 'assets/test.png',
  //         actionColor: '#4CAF50',
  //         textColor: '#ffffff',
  //         incomingCallNotificationChannelName: 'Incoming Call',
  //         missedCallNotificationChannelName: 'Missed Call',
  //       ),
  //       ios: const IOSParams(
  //         iconName: 'CallKitLogo',
  //         handleType: '',
  //         supportsVideo: true,
  //         maximumCallGroups: 2,
  //         maximumCallsPerCallGroup: 1,
  //         audioSessionMode: 'default',
  //         audioSessionActive: true,
  //         audioSessionPreferredSampleRate: 44100.0,
  //         audioSessionPreferredIOBufferDuration: 0.005,
  //         supportsDTMF: true,
  //         supportsHolding: true,
  //         supportsGrouping: false,
  //         supportsUngrouping: false,
  //         ringtonePath: 'system_ringtone_default',
  //       ),
  //     );
  //     await FlutterCallkitIncoming.showCallkitIncoming(params);
  //   });
  // }

  Future<void> endCurrentCall() async {
    initCurrentCall();
    await FlutterCallkitIncoming.endCall(_currentUuid!);
  }

  Future<void> startOutGoingCall() async {
    sendMessage(
      title: 'hello',
      subTitle: 'hello',
      token:
          'eb_gIbZpSGCkYEMHHjZZtX:APA91bEBGE0VqZrTHwCpvVRRwWai_pxGZu3UNWcexegfK0lRKF3xo41KldzcLWmhWtV70QZlCFJ20FdWcirVpsKQPUPTrYMKRYrR-A-0ngV8vOMS6Eq9hBO87C0tSvSk0WfICzWozDqh',
      data: {
        "senderName": 'akash kachhi',
        "avatar": 'https://i.pravatar.cc/100',
        "UserId": '102',
        "senderId": '103',
        "type": '3',
        "id": 0,
        "sound": "default",
        "alert": "",
        "title": "",
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "status": "done"
      },
    );
    _currentUuid = _uuid.v4();
    final params = CallKitParams(
      id: _currentUuid,
      nameCaller: 'akash kachhi',
      handle: '0123456789',
      type: 1,
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
      ios: const IOSParams(handleType: 'number'),
    );
    await FlutterCallkitIncoming.startCall(params);
    Get.to(()=>const CallScreen());
  }

  Future<void> activeCalls() async {
    var calls = await FlutterCallkitIncoming.activeCalls();
    print(calls);
  }

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
            Get.to(() => const CallScreen());
            // NavigationService.instance.pushNamedIfNotCurrent(AppRoute.callingPage, args: event.body);
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

  //check with https://webhook.site/#!/2748bc41-8599-4093-b8ad-93fd328f1cd2
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
  required String title,
  required String subTitle,
  required String token,
  required Map<String, dynamic> data,
}) async {
  Map data0 = {
    "data": data,
    // "notification": {
    //   "title": title,
    //   "body": subTitle,
    //   "sound": "default",
    //   "priority": "high",
    //   "importance": 4,
    //   "fullScreenIntent": true
    // },
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
