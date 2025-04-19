import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlatformAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Update FCM token for Android only
      if (!kIsWeb) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await _updateUserToken(credential.user!.uid, fcmToken);
      }

      return credential;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        // Web-specific Google sign-in
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Android-specific Google sign-in
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);

        // Get FCM token for Android
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await _updateUserToken(userCredential.user!.uid, fcmToken);
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  static Future<void> _updateUserToken(String uid, String? token) async {
    await _firestore.collection('users').doc(uid).update({
      'fcmToken': token,
      'lastLogin': FieldValue.serverTimestamp(),
      'platform': kIsWeb ? 'web' : 'android'
    });
  }

  static Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
        // Clear FCM token on Android
        await _updateUserToken(_auth.currentUser!.uid, null);
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }
}
