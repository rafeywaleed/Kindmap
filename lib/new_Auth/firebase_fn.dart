import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirestoreServices {
  static Future<void> saveUser(String name, String email, String uid) async {
    try {
      // Get FCM token only for Android
      String? fcmToken;
      if (!kIsWeb) {
        fcmToken = await FirebaseMessaging.instance.getToken();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'helped': 0,
        'fcmToken': fcmToken,
        'platform': kIsWeb ? 'web' : 'android',
        'joined': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }
}
