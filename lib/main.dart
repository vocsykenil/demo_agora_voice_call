// Import the generated file

import 'package:agora_uikit/agora_uikit.dart';
import 'package:demo_agora_ui_kit/voiceCall/calling_page.dart';
import 'package:demo_agora_ui_kit/home_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';

import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:uuid/uuid.dart';

import 'firebase_options.dart';
import 'loginScreen.dart';

GetStorage box = GetStorage();
bool backgroundMessageHandled = false;


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  showCallkitIncoming(const Uuid().v4(), message);
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
    type: 0,
    duration: 10000,
    textAccept: 'Accept',
    textDecline: 'Decline',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: true,
      subtitle: 'Missed call',
      callbackText: 'Call back',
    ),
    extra: <String, dynamic>{
      'UserId': message.data['UserId'],
      "senderId": message.data['senderId'],
      "channelName": message.data['channelName'],
    },
    headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
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
  await FlutterCallkitIncoming.showCallkitIncoming(params);});
}

Future<void> main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final Uuid _uuid;
  String? _currentUuid;

  late final FirebaseMessaging _firebaseMessaging;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _uuid = const Uuid();
    initFirebase();
    checkAndNavigationCallingPage();
  }

  Future<void> checkAndNavigationCallingPage() async {
    var currentCall = await getCurrentCall();
    print('current call ======> $currentCall');
    if (currentCall != null) {
      Get.to(() => CallScreen(
            channelName: currentCall['extra']['channelName'],
      ));
    }
  }

  Future<dynamic> getCurrentCall() async {
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> initFirebase() async {
    await Permission.notification.isDenied
        ? Permission.notification.request()
        : null;

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _firebaseMessaging = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('hello how are you');
      print(
          'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
      _currentUuid = _uuid.v4();

      showCallkitIncoming(_currentUuid!, message);
    });
    try {
      _firebaseMessaging.getToken().then((token) {
            box.write('token', token);
            print('Device Token FCM: $token');
          });
    } catch (e) {
      print('token error ==> $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('isLogin ====> ${box.read('isLogin')}');
    return GetMaterialApp(
      home: box.read('isLogin') != null && box.read('isLogin') == true
          ? const HomePage()
          : LoginScreen(),
      theme: ThemeData.light(),
    );
  }

  Future<void> getDevicePushTokenVoIP() async {
    var devicePushTokenVoIP =
        await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    print(devicePushTokenVoIP);
  }
}
