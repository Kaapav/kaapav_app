// lib/main.dart
import 'dart:io' show Platform;
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';
import 'app.dart';
import 'services/notification_service.dart';
import 'utils/logger.dart';
import 'dart:convert';  // For jsonEncode
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


// ═══════════════════════════════════════════════════════════════
// BACKGROUND HANDLER — MUST BE TOP-LEVEL (Outside any class!)
// This runs in a SEPARATE ISOLATE when app is killed/background
// ═══════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔥 BACKGROUND HANDLER FIRED: ${message.data}');

  final plugin = FlutterLocalNotificationsPlugin();
  
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);
  await plugin.initialize(settings);

  final title = message.notification?.title ?? 
                message.data['title'] ?? 
                'New Message';
  final body = message.notification?.body ?? 
               message.data['body'] ?? 
               message.data['message'] ?? 
               '';

  await plugin.show(
    message.hashCode,
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
    payload: jsonEncode(message.data),
  ); 
} 

// ═══════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase FIRST
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Register background handler BEFORE runApp (ONLY ONCE!)
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);


  // Setup Crashlytics
if (!Platform.isWindows) {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

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
