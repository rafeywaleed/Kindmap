import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirestoreServices {
  static Future<void> saveUser(String name, String email, String uid) async {
    try {
      // Get FCM token for Android
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'helped': 0,
        'fcmToken': fcmToken,
        'platform': 'android',
        'joined': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }
}
