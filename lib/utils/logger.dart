import 'dart:developer' as developer;

class Logger {
  Logger._();

  static void info(String message) {
    developer.log('ℹ️ $message', name: 'KAAPAV', level: 800);
  }

  static void error(String message, [dynamic err, StackTrace? stackTrace]) {
    developer.log('❌ $message', name: 'KAAPAV', level: 1000, error: err, stackTrace: stackTrace);
  }

  static void warning(String message) {
    developer.log('⚠️ $message', name: 'KAAPAV', level: 900);
  }

  static void warn(String message) => warning(message);

  static void debug(String message) {
    assert(() {
      developer.log('🔍 $message', name: 'KAAPAV', level: 500);
      return true;
    }());
  }

  static void network(String method, String url, {int? statusCode, String? error}) {
    final status = statusCode != null ? ' [$statusCode]' : '';
    final err = error != null ? ' → $error' : '';
    developer.log('🌐 $method $url$status$err', name: 'KAAPAV', level: 700);
  }

  static void ws(String message) {
    developer.log('🔌 $message', name: 'KAAPAV-WS', level: 700);
  }

  static void fcm(String message) {
    developer.log('🔔 $message', name: 'KAAPAV-FCM', level: 700);
  }

  static void auth(String message) {
    developer.log('🔐 $message', name: 'KAAPAV-AUTH', level: 700);
  }

  static void cache(String message) {
    developer.log('💾 $message', name: 'KAAPAV-CACHE', level: 600);
  }

  static void success(String message) {
    developer.log('✅ $message', name: 'KAAPAV', level: 800);
  }

  static void offline(String message) {
    developer.log('📴 $message', name: 'KAAPAV-OFFLINE', level: 900);
  }
}

/// Alias — some files use AppLogger, some use Logger. Both work.
class AppLogger {
  AppLogger._();
  static void info(String m) => Logger.info(m);
  static void error(String m, [dynamic e, StackTrace? s]) => Logger.error(m, e, s);
  static void warning(String m) => Logger.warning(m);
  static void warn(String m) => Logger.warn(m);
  static void debug(String m) => Logger.debug(m);
  static void network(String method, String url, {int? statusCode, String? error}) =>
      Logger.network(method, url, statusCode: statusCode, error: error);
  static void ws(String m) => Logger.ws(m);
  static void fcm(String m) => Logger.fcm(m);
  static void auth(String m) => Logger.auth(m);
  static void cache(String m) => Logger.cache(m);
  static void success(String m) => Logger.success(m);
  static void offline(String m) => Logger.offline(m);
}