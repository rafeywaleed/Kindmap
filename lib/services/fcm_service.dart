// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kindmap/firebase_options.dart';

import '../config/app_theme.dart';
import '../config/route_observer.dart';

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
    // On web, requesting notification permission / a token requires a
    // secure context (HTTPS or localhost) and a registered service worker.
    // Over plain HTTP (e.g. testing via a LAN IP) these calls throw, but the
    // rest of init (foreground message listeners, etc.) should still run.
    try {
      await _firebaseMessaging.requestPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }

    try {
      final fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $fcmToken');
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // Configure foreground notification presentation
    try {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint(
          'Failed to set foreground notification presentation options: $e');
    }

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
        _showWebForegroundNotification(notification);
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

  /// Shows an in-app banner for foreground push notifications on web, since
  /// flutter_local_notifications has no web implementation and the browser
  /// only surfaces notifications via the service worker when the tab is
  /// unfocused.
  void _showWebForegroundNotification(RemoteNotification notification) {
    final context = kNavigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    final theme = KMTheme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.secondaryBackground,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.primaryText.withOpacity(0.06)),
        ),
        duration: const Duration(seconds: 4),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.notifications_active_rounded,
                  size: 18, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notification.title != null)
                    Text(
                      notification.title!,
                      style: theme.bodyMedium.copyWith(
                        fontFamily: 'Readex Pro',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  if (notification.body != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.body!,
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
