import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';


class LocalNotification {

  Future<void> setTokenOnFirebase(String token) async {
    print('uid  =====> ${box.read('uid')}');
    final data = FirebaseFirestore.instance
        .collection('token')
        .doc(box.read('uid'));
      await data.get().then((value) {

        if (value.exists) {
          data.update({'token': token});
        }else {
          data.set({'token': token});
          box.write('uid',data.id);
        }
      });
  }

  Future<String> getToken(String userId) async {
    Map<String, dynamic> data1 = {};
    final data = FirebaseFirestore.instance.collection('token').doc(userId);
    await data.get().then((value) {
      data1 = value.data() as Map<String, dynamic>;
    });
    return data1['token'];
  }
}
