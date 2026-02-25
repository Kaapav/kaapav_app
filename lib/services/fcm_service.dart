//kaapav_app\lib\services\fcm_service.dart
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../config/routes.dart';

// ─── BACKGROUND HANDLER (top-level, outside class) ───────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background: system tray handles it automatically via FCM
  debugPrint('[FCM] Background message: ${message.messageId}');
}

// ─── LOCAL NOTIFICATION CHANNEL ──────────────────────────────────────────────
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'kaapav_messages',
  'KAAPAV Messages',
  description: 'WhatsApp Business message notifications',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // ─── INIT (call once after Firebase.initializeApp) ───────────────────────
  Future<void> init() async {
    // 1. Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup local notifications channel (Android)
    await _localNotif
        .resolvePlatformSpecificImplementation
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Init local notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotifTap,
    );

    // 4. Get FCM token
    _fcmToken = await _fcm.getToken();
    debugPrint('[FCM] Token: $_fcmToken');

    // 5. Token refresh listener
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('[FCM] Token refreshed: $newToken');
      // TODO: send to worker POST /api/push/fcm-register
    });

    // 6. Foreground message handler
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 7. Notification tap when app in background (but not killed)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotifOpenedApp);

    // 8. Check if app was launched from a notification (killed state)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage.data);
    }

    // 9. Foreground show heads-up (Android default suppresses these)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ─── FOREGROUND: show heads-up banner via local notifications ────────────
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');

    final notif = message.notification;
    if (notif == null) return;

    _localNotif.show(
      message.hashCode,
      notif.title ?? 'KAAPAV',
      notif.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ─── TAP: local notification ──────────────────────────────────────────────
  void _onNotifTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!);
      _handleNavigation(data);
    } catch (_) {}
  }

  // ─── TAP: background FCM notification ────────────────────────────────────
  void _onNotifOpenedApp(RemoteMessage message) {
    _handleNavigation(message.data);
  }

  // ─── NAVIGATE to chat window on tap ──────────────────────────────────────
  void _handleNavigation(Map<String, dynamic> data) {
    final phone = data['phone'] as String?;
    if (phone == null) return;

    // Navigate to chat window
    AppRoutes.navigatorKey.currentState?.pushNamed(
      AppRoutes.chatWindow,
      arguments: {'phone': phone, 'name': data['name'] ?? phone},
    );
  }
}