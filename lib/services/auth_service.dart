// lib/services/auth_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../config/constants.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ═══════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<void> saveTokenExpiry(String expiry) async {
    await _storage.write(key: AppConstants.tokenExpiryKey, value: expiry);
  }

  static Future<String?> getTokenExpiry() async {
    try {
      return await _storage.read(key: AppConstants.tokenExpiryKey);
    } catch (_) {
      return null;
    }
  }

  /// Parse JWT payload without verification (client-side only)
  static Map<String, dynamic>? parseJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      // Add padding if needed
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Check if token is expiring within buffer time
  static bool isTokenExpiringSoon(String token) {
    final payload = parseJwt(token);
    if (payload == null || payload['exp'] == null) return false;

    final expiry = DateTime.fromMillisecondsSinceEpoch(
      (payload['exp'] as int) * 1000,
    );
    final buffer = DateTime.now().add(AppConstants.tokenRefreshBuffer);
    return expiry.isBefore(buffer);
  }

  /// Check if token is fully expired
  static bool isTokenExpired(String token) {
    final payload = parseJwt(token);
    if (payload == null || payload['exp'] == null) return false;

    final expiry = DateTime.fromMillisecondsSinceEpoch(
      (payload['exp'] as int) * 1000,
    );
    return expiry.isBefore(DateTime.now());
  }

  // ═══════════════════════════════════════════════════════════
  // USER DATA
  // ═══════════════════════════════════════════════════════════

  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: AppConstants.userDataKey, value: userData);
  }

  static Future<String?> getUserData() async {
    try {
      return await _storage.read(key: AppConstants.userDataKey);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PIN MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  static Future<void> savePin(String pin) async {
    // Hash the PIN before storing
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: AppConstants.pinHashKey, value: hash);
    await _storage.write(key: AppConstants.pinKey, value: 'set');
  }

  static Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: AppConstants.pinKey);
      return pin == 'set';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: AppConstants.pinHashKey);
      if (storedHash == null) return false;

      final inputHash = sha256.convert(utf8.encode(pin)).toString();
      return storedHash == inputHash;
    } catch (_) {
      return false;
    }
  }

  static Future<void> changePin(String oldPin, String newPin) async {
    final valid = await verifyPin(oldPin);
    if (!valid) throw Exception('Current PIN is incorrect');
    await savePin(newPin);
  }

  static Future<void> removePin() async {
    await _storage.delete(key: AppConstants.pinKey);
    await _storage.delete(key: AppConstants.pinHashKey);
  }

  // ═══════════════════════════════════════════════════════════
  // BIOMETRIC
  // ═══════════════════════════════════════════════════════════

  static Future<bool> isBiometricEnabled() async {
    try {
      final val = await _storage.read(key: AppConstants.biometricEnabledKey);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: AppConstants.biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FIRST LAUNCH
  // ═══════════════════════════════════════════════════════════

  static Future<bool> isFirstLaunch() async {
    try {
      final val = await _storage.read(key: AppConstants.firstLaunchKey);
      return val == null;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setFirstLaunchDone() async {
    await _storage.write(key: AppConstants.firstLaunchKey, value: 'done');
  }

  // ═══════════════════════════════════════════════════════════
  // CLEAR ALL
  // ═══════════════════════════════════════════════════════════

  static Future<void> clearAll() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.tokenExpiryKey);
    await _storage.delete(key: AppConstants.userDataKey);
    // Keep PIN and biometric settings — user might want to re-login
  }

  /// Full wipe — including PIN and biometric
  static Future<void> fullWipe() async {
    await _storage.deleteAll();
  }
}