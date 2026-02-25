// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui';
import 'dart:convert';
import 'app.dart';
import 'services/notification_service.dart';
import 'utils/logger.dart';

// ═══════════════════════════════════════════════════════════════
// BACKGROUND HANDLER — MUST BE TOP-LEVEL (Outside any class!)
// This runs in a SEPARATE ISOLATE when app is killed/background
// ═══════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  await Firebase.initializeApp();
  
  debugPrint('🔔 Background message received: ${message.messageId}');
  
  // Show local notification for DATA-only messages
  // (notification messages are shown automatically by system)
  if (message.notification == null && message.data.isNotEmpty) {
    final plugin = FlutterLocalNotificationsPlugin();
    
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await plugin.initialize(settings);
    
    await plugin.show(
      message.hashCode,
      message.data['title'] ?? 'New Message',
      message.data['body'] ?? message.data['message'] ?? '',
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
      payload: jsonEncode(message.data),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase FIRST
  await Firebase.initializeApp();
  
  // Register background handler BEFORE runApp (ONLY ONCE!)
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  // Setup Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize notifications
  try {
    await NotificationService.instance.initialize();
    AppLogger.info('✅ Services initialized');
  } catch (e) {
    AppLogger.error('❌ Service init error: $e');
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}