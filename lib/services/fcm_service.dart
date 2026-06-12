// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kindmap/firebase_options.dart';

Future<void> handleBackgroundMessage(RemoteMessage? message) async {
  // Required: ensure Firebase is initialized in background isolate
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  if (message == null) return;

  debugPrint('🔔 Background message received: ${message.notification?.title}');
  // Optional: handle routing here if needed
  // navigatorKey.currentState?.pushNamed('/map');
}

class FCM {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Android specific channel
  final _androidChannel = const AndroidNotificationChannel(
      'high_importance_channel', 'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.max);

  Future<void> initNotifications() async {
    await _initMobileNotifications();
  }

  Future<void> _initMobileNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $fcmToken');

    // Configure foreground notification presentation
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    // Topic subscriptions aren't supported on web clients; web users would
    // need to be subscribed server-side via the Admin SDK using their token.
    if (!kIsWeb) {
      await _firebaseMessaging.subscribeToTopic('need_help');
    }

    // flutter_local_notifications has no web implementation, and
    // onBackgroundMessage is handled by firebase-messaging-sw.js on web.
    if (!kIsWeb) {
      // Initialize local notifications
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (payload) {
          if (payload.payload != null) {
            final message = RemoteMessage.fromMap(jsonDecode(payload.payload!));
            handleBackgroundMessage(message);
          }
        },
      );

      // Create notification channel
      final platform = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await platform?.createNotificationChannel(_androidChannel);

      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    }

    // Handle different message scenarios
    _firebaseMessaging.getInitialMessage().then(handleBackgroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleBackgroundMessage);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;

      if (kIsWeb) {
        debugPrint('🔔 Foreground message: ${notification.title}');
        return;
      }

      await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.toMap()));
    });
  }
}
