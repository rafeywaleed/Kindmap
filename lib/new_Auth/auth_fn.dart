// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:kindmap/new_Auth/platform_auth_service.dart';

class AuthServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> signupUser(
      String email, String password, String name, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user!.updateDisplayName(name);

      // Get FCM token based on platform
      String? fcmToken;
      if (!kIsWeb) {
        fcmToken = await FirebaseMessaging.instance.getToken();
      }

      // Save user data
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'created': FieldValue.serverTimestamp(),
        'fcmToken': fcmToken,
        'platform': kIsWeb ? 'web' : 'android',
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful')));

      Navigator.pushReplacementNamed(context, '/introScreens');
    } on FirebaseAuthException catch (e) {
      String message = _getAuthErrorMessage(e.code);
      _showErrorSnackBar(context, message);
    } catch (e) {
      _showErrorSnackBar(context, e.toString());
    }
  }

  static Future<void> signinUser(
      String email, String password, BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Update FCM token on login
      if (!kIsWeb) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .update({
          'fcmToken': fcmToken,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Login Successful')));

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String message = _getAuthErrorMessage(e.code);
      _showErrorSnackBar(context, message);
    } catch (e) {
      _showErrorSnackBar(context, e.toString());
    }
  }

  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email already exists';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Invalid password';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Authentication failed';
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
