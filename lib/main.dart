// Import the generated file

import 'dart:io';

import 'package:agora_uikit/agora_uikit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_agora_ui_kit/vedio_call/vedio_call.dart';
import 'package:demo_agora_ui_kit/voiceCall/calling_page.dart';
import 'package:demo_agora_ui_kit/home_page.dart';
import 'package:demo_agora_ui_kit/voiceCall/voice_call_controller.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';

import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'package:uuid/uuid.dart';

import 'firebase_options.dart';
import 'loginScreen.dart';

GetStorage box = GetStorage();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  BackgroundListener().listenerEvent(BackgroundListener().onEvent);
  if (message.data['type'] == 'is Calling you') {
    showCallkitIncoming(const Uuid().v4(), message);
  } else if (message.data['type'] == 'Cut') {
    FlutterCallkitIncoming.endAllCalls();
  }
}

Future<void> showCallkitIncoming(String uuid, RemoteMessage message) async {
  const Uuid uuid = Uuid();
  String _currentUuid = '';
  _currentUuid = uuid.v4();

  print('message data ===> ${message.data}');
  print('message data type ===> ${message.data.runtimeType}');

  await Future.delayed(const Duration(seconds: 1), () async {
    final params = CallKitParams(
      id: _currentUuid,
      nameCaller: message.data['senderName'],
      appName: 'Callkit',
      avatar: message.data['avatar'],
      handle: '0123456789',
      type: int.parse(message.data['isVoiceCall']),
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: <String, dynamic>{
        'UserId': message.data['UserId'],
        "senderId": message.data['senderId'],
        "channelName": message.data['channelName'],
        "isVoiceCall": message.data['isVoiceCall'],
      },
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#27B2AC',
        backgroundUrl: 'assets/test.png',
        actionColor: '#4CAF50',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
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
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  });
}

VoiceCallController callController = Get.put(VoiceCallController());

Future<void> main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();

  PermissionStatus status = await Permission.microphone.status;
  if (status.isDenied) {
    await Permission.microphone.request();
  } else if (status.isPermanentlyDenied) {
    print('status permission ===> $status');
  }
  callController.setupVoiceSDKEngine();
  await Permission.notification.status.then((value) {
    print('value of notification ===> ${value}');
    // if (value) {
    try {
      Permission.notification.request();
    } catch (e) {
      print(e);
    }
    print('value of notification ===> ${value}');
    // }
  });
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FlutterCallkitIncoming.endAllCalls();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (Platform.isAndroid) {
    initFirebase();
  }
  runApp(MyApp());
}

Future<void> initFirebase() async {
  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('hello how are you');
    print(
        'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
    if (message.data['type'] == 'is Calling you') {
      showCallkitIncoming(const Uuid().v4(), message);
    } else if (message.data['type'] == 'Cut') {
      FlutterCallkitIncoming.endAllCalls();
    }
    // showCallkitIncoming(_currentUuid!, message);
  });
}
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final Uuid uuid;
  String? currentUuid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    uuid = const Uuid();
    checkAndNavigationCallingPage();
  }

  Future<void> checkAndNavigationCallingPage() async {
    var currentCall = await getCurrentCall();
    print('current call ======> $currentCall');
    if (currentCall != null) {
      callController.join(currentCall['extra']['channelName']);

      if (currentCall['extra']['isVoiceCall'] == '0') {
        Get.to(() => CallScreen(
              chanelName: currentCall['extra']['channelName'],
              isSelfCut: false,
              data: const {},
            ));
      } else {
        Get.to(() => VideoCallPage(
          data: {},
          isSelfCut: false,
              channelName: currentCall['extra']['channelName'],
            ));
      }
    }
  }

  Future<dynamic> getCurrentCall() async {
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        print('DATA: $calls');
        currentUuid = calls[0]['id'];
        return calls[0];
      } else {
        currentUuid = "";
        return null;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    print('isLogin ====> ${box.read('isLogin')}');
    return GlobalLoaderOverlay(
      useDefaultLoading: false,
      overlayWidgetBuilder: (progress) {
        return const Loading();
      },
      child: GetMaterialApp(
        home: box.read('isLogin') != null && box.read('isLogin') == true
            ? const HomePage()
            : LoginScreen(),
        theme: ThemeData.light(),
      ),
    );
  }
}

class BackgroundListener {
  void get(Uri parse) {}
  Future<void> requestHttp(content) async {
    get(Uri.parse(
        'https://webhook.site/2748bc41-8599-4093-b8ad-93fd328f1cd2?data=$content'));
  }



  String onEvent(CallEvent event) {
    return '${event.toString()}\n' ;
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

}