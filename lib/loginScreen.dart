import 'dart:developer';
import 'dart:io';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_agora_ui_kit/home_page.dart';
import 'package:demo_agora_ui_kit/voiceCall/calling_page.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';

import 'main.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final email = TextEditingController();
  final pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextFormField(
            controller: email,
            decoration: const InputDecoration(hintText: 'email'),
          ),
          const SizedBox(
            height: 20,
          ),
          TextFormField(
            decoration: const InputDecoration(hintText: 'password'),
            controller: pass,
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
              onPressed: () async {
                FirebaseAuth auth = FirebaseAuth.instance;
                try {
                  await auth.createUserWithEmailAndPassword(
                    email: email.text.trim(),
                    password: pass.text.trim(),
                  ).then((value) async { box.write('uid',value.user?.uid);
                  var devicePushTokenVoIP =
                  await FlutterCallkitIncoming.getDevicePushTokenVoIP();
                  String? token = await FirebaseMessaging.instance.getToken();
                    FirebaseFirestore.instance.collection('users').doc(value.user?.uid).set({"email":value.user?.email,"uid":value.user?.uid,"device":Platform.isAndroid?'android':'ios',"token":Platform.isAndroid?token:devicePushTokenVoIP});
                  box.write('uid',value.user?.uid);
                    box.write('isLogin',true);
                    Get.to(()=>const HomePage());
                  });
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'weak-password') {
                    showMessage('The password provided is too weak.');
                    log('The password provided is too weak.');
                  } else if (e.code == 'email-already-in-use') {
                    auth.signInWithEmailAndPassword(
                            email: email.text, password: pass.text)
                        .then((value) async {
                      var devicePushTokenVoIP =
                          await FlutterCallkitIncoming.getDevicePushTokenVoIP();
                      String? token = await FirebaseMessaging.instance.getToken();
                      FirebaseFirestore.instance.collection('users').doc(value.user?.uid).update({"email":value.user?.email,"uid":value.user?.uid,"device":Platform.isAndroid?'android':'ios',"token":Platform.isAndroid?token:devicePushTokenVoIP});
                      box.write('uid',value.user?.uid);
                          box.write('isLogin',true);
                          Get.to(()=>const HomePage());
                          log('value  ======> ${value.user?.uid}');
                    });
                    log('The account already exists for that email.');
                  }
                } catch (e) {
                  log(e.toString());
                }
              },
              child: const Text('Login'))
        ]),
      ),
    );
  }
}
