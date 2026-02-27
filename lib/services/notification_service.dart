// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import '../utils/logger.dart';
import 'api/api_client.dart';

// ═══════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
// ═══════════════════════════════════════════════════════════════

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  String? _token;
  String? get token => _token;
  bool _initialized = false;

  // Callback when notification tapped
  void Function(String phone)? onNotificationTap;

  // ───────────────────────────────────────────────────────────────
  // INITIALIZE
  // ───────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      AppLogger.info('🔔 Initializing FCM...');

      // Request permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        AppLogger.warn('🔔 Notification permission denied');
        return;
      }

      // Initialize local notifications
      await _initLocal();

      // Get FCM token
      _token = await _fcm.getToken();
      if (_token != null) {
        AppLogger.success('🔔 FCM Token obtained');
        // Print first 20 chars for debugging
        AppLogger.info('🔔 Token: ${_token!.substring(0, 20)}...');
        await _sendTokenToBackend(_token!);
      } else {
        AppLogger.warn('🔔 FCM Token is null');
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _token = newToken;
        AppLogger.info('🔔 FCM Token refreshed');
        _sendTokenToBackend(newToken);
      });

      // Foreground messages — show local notification
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // NOTE: Background handler is registered in main.dart — NOT here!
      // FirebaseMessaging.onBackgroundMessage() should only be called ONCE

      // Notification tap (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Notification tap (app terminated)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        // Delay to ensure app is ready
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationTap(initialMessage);
        });
      }

      _initialized = true;
      AppLogger.success('🔔 FCM initialized successfully');
    } catch (e, stack) {
      AppLogger.error('🔔 FCM init failed', e, stack);
    }
  }

  // ───────────────────────────────────────────────────────────────
  // LOCAL NOTIFICATIONS SETUP
  // ───────────────────────────────────────────────────────────────

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            final phone = data['phone'] as String?;
            if (phone != null) {
              AppLogger.info('🔔 Local notification tapped: $phone');
              onNotificationTap?.call(phone);
            }
          } catch (e) {
            AppLogger.warn('🔔 Failed to parse notification payload: $e');
          }
        }
      },
    );

    // Create Android notification channel
    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'kaapav_messages',
          'Messages',
          description: 'New WhatsApp messages',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      AppLogger.info('🔔 Notification channel created');
    }
  }

  // ───────────────────────────────────────────────────────────────
  // HANDLE FOREGROUND MESSAGE
  // ───────────────────────────────────────────────────────────────

      Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 
                  message.data['title'] ?? 
                  'New message';
    final body = message.notification?.body ?? 
                 message.data['body'] ?? 
                 message.data['message'] ?? 
                 '';
    final phone = message.data['phone'];

    AppLogger.info('🔔 Foreground message: $title');

    await _local.show(
      phone?.hashCode ?? message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kaapav_messages',
          'Messages',
          channelDescription: 'New WhatsApp messages',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          visibility: NotificationVisibility.public,
        ),
      ),
      payload: jsonEncode({'phone': phone, ...message.data}),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // HANDLE NOTIFICATION TAP
  // ───────────────────────────────────────────────────────────────

  void _handleNotificationTap(RemoteMessage message) {
    final phone = message.data['phone'];
    AppLogger.info('🔔 FCM notification tapped: $phone');

    if (phone != null && onNotificationTap != null) {
      onNotificationTap!(phone);
    }
  }

  // ───────────────────────────────────────────────────────────────
  // SEND TOKEN TO BACKEND
  // ───────────────────────────────────────────────────────────────

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiClient.instance.post(
        '/api/push/fcm-register',
        data: {
          'token': token,
          'platform': 'android',
          'deviceId': 'samsung-s23-ultra',
        },
        skipAuth: true,  // In case user isn't logged in yet
      );
      AppLogger.success('🔔 Token registered with backend');
    } catch (e) {
      AppLogger.warn('🔔 Token send failed (will retry): $e');
    }
  }

  // ───────────────────────────────────────────────────────────────
  // PUBLIC: SHOW NOTIFICATION
  // ───────────────────────────────────────────────────────────────

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kaapav_messages',
          'Messages',
          channelDescription: 'New WhatsApp messages',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showMessageNotification({
    required String phone,
    required String name,
    required String message,
  }) async {
    await showNotification(
      title: name,
      body: message,
      payload: jsonEncode({'phone': phone}),
    );
  }

  Future<void> cancelForPhone(String phone) async {
    await _local.cancel(phone.hashCode);
  }

  Future<void> cancelAll() async {
    await _local.cancelAll();
  }

  Future<void> refreshToken() async {
    try {
      await _fcm.deleteToken();
      _token = await _fcm.getToken();
      if (_token != null) {
        await _sendTokenToBackend(_token!);
        AppLogger.success('🔔 Token refreshed and sent');
      }
    } catch (e) {
      AppLogger.error('🔔 Token refresh failed', e);
    }
  }
}