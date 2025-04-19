// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kindmap/main.dart';

Future<void> handleBackgroundMessage(RemoteMessage? message) async {
  if (message == null) return;
  // Handle background messages differently for web and mobile
  if (!kIsWeb) {
    navigatorKey.currentState?.pushNamed('/map');
  }
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
    if (kIsWeb) {
      await _initWebNotifications();
    } else {
      await _initMobileNotifications();
    }
  }

  Future<void> _initWebNotifications() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _firebaseMessaging.getToken();
        print('FCM Web Token: $token');

        await _firebaseMessaging.subscribeToTopic('need_help');

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((message) {
          print(
              'Received web foreground message: ${message.notification?.title}');
          // Implement web notification display logic here
        });

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
      }
    } catch (e) {
      print('Error initializing web notifications: $e');
    }
  }

  Future<void> _initMobileNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    print('Mobile FCM Token: $fcmToken');

    // Configure foreground notification presentation
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    // Subscribe to topics
    await _firebaseMessaging.subscribeToTopic('need_help');

    // Initialize local notifications
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
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
    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);

    // Handle different message scenarios
    _firebaseMessaging.getInitialMessage().then(handleBackgroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;

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
