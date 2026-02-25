// lib/providers/auth_provider.dart
// ═══════════════════════════════════════════════════════════════════════════════
// KAAPAV AUTH PROVIDER — Production Grade (Samsung Knox Compatible) — FIXED
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';
import '../services/api/api_client.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum AuthStatus { initializing, locked, authenticated }

enum AppBiometricType { none, fingerprint, face, iris, multiple }

enum AuthErrorType {
  none,
  invalidPin,
  biometricFailed,
  biometricNotAvailable,
  biometricNotEnrolled,
  biometricLocked,
  biometricCancelled,
  unknown,
}

extension AuthErrorTypeX on AuthErrorType {
  String get message {
    switch (this) {
      case AuthErrorType.none:
        return '';
      case AuthErrorType.invalidPin:
        return 'Invalid PIN. Please try again.';
      case AuthErrorType.biometricFailed:
        return 'Biometric verification failed.';
      case AuthErrorType.biometricNotAvailable:
        return 'Biometric not available on this device.';
      case AuthErrorType.biometricNotEnrolled:
        return 'No biometrics enrolled. Set up fingerprint in device settings.';
      case AuthErrorType.biometricLocked:
        return 'Biometric locked. Too many failed attempts.';
      case AuthErrorType.biometricCancelled:
        return ''; // Don't show error for user cancellation
      case AuthErrorType.unknown:
        return 'Authentication failed. Please try again.';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH STATE
// ═══════════════════════════════════════════════════════════════════════════════

@immutable
class AuthState {
  final AuthStatus status;
  final User? user;
  final AuthErrorType errorType;
  final String? errorMessage;
  final bool isLoading;
  final bool biometricAvailable;
  final AppBiometricType biometricType;
  final bool pinSet;
  final int failedAttempts;
  final DateTime? lockedUntil;

  const AuthState({
    this.status = AuthStatus.initializing,
    this.user,
    this.errorType = AuthErrorType.none,
    this.errorMessage,
    this.isLoading = false,
    this.biometricAvailable = false,
    this.biometricType = AppBiometricType.none,
    this.pinSet = false,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  bool get hasError =>
      errorType != AuthErrorType.none &&
      errorType != AuthErrorType.biometricCancelled;
  String get displayError => errorMessage ?? errorType.message;
  bool get isLockedOut =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);
  int get lockoutSecondsRemaining {
    if (lockedUntil == null) return 0;
    final remaining = lockedUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  String get biometricLabel {
    switch (biometricType) {
      case AppBiometricType.face:
        return 'Face ID';
      case AppBiometricType.fingerprint:
        return 'Fingerprint';
      case AppBiometricType.iris:
        return 'Iris';
      case AppBiometricType.multiple:
        return 'Biometric';
      case AppBiometricType.none:
        return 'Biometric';
    }
  }

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    AuthErrorType? errorType,
    String? errorMessage,
    bool? isLoading,
    bool? biometricAvailable,
    AppBiometricType? biometricType,
    bool? pinSet,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearError = false,
    bool clearLockout = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorType:
          clearError ? AuthErrorType.none : (errorType ?? this.errorType),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricType: biometricType ?? this.biometricType,
      pinSet: pinSet ?? this.pinSet,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLockout ? null : (lockedUntil ?? this.lockedUntil),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════════

class AuthNotifier extends StateNotifier<AuthState> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _masterPin = '1428';
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(seconds: 30);

  AuthNotifier() : super(const AuthState()) {
    _initialize();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    AppLogger.info('🔐 Auth: Initializing...');

    try {
      await AuthService.savePin(_masterPin);

      // Check biometric availability (Samsung Knox safe)
      final bioResult = await _checkBiometricAvailability();

      // Force-enable biometric if available
      if (bioResult.available) {
        await AuthService.setBiometricEnabled(true);
      }

      final defaultUser = User(
        id: 1,
        userId: 'owner',
        email: 'kaapavin@gmail.com',
        name: 'KAAPAV Owner',
        role: 'admin',
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
      );

      state = state.copyWith(
        status: AuthStatus.locked,
        user: defaultUser,
        biometricAvailable: bioResult.available,
        biometricType: bioResult.type,
        pinSet: true,
      );

      AppLogger.success(
          '🔐 Auth: Ready (bio: ${bioResult.available}, type: ${bioResult.type})');
    } catch (e, stack) {
      AppLogger.error('🔐 Auth: Init failed', e, stack);
      state = state.copyWith(
        status: AuthStatus.locked,
        pinSet: true,
        biometricAvailable: false,
        biometricType: AppBiometricType.none,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BIOMETRIC AVAILABILITY CHECK (Samsung Knox Safe)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<({bool available, AppBiometricType type})>
      _checkBiometricAvailability() async {
    try {
      // Step 1: Check if device has biometric hardware
      final isSupported = await _localAuth.isDeviceSupported();
      AppLogger.info('🔐 Biometric: isDeviceSupported = $isSupported');

      if (!isSupported) {
        return (available: false, type: AppBiometricType.none);
      }

      // Step 2: Check if we can check biometrics (Knox may block this)
      bool canCheck = false;
      try {
        canCheck = await _localAuth.canCheckBiometrics;
        AppLogger.info('🔐 Biometric: canCheckBiometrics = $canCheck');
      } catch (e) {
        // Knox blocks this call - assume available since device supports it
        AppLogger.warn('🔐 Biometric: canCheckBiometrics blocked (Knox?): $e');
        canCheck = true; // Assume yes on Samsung
      }

      // Step 3: Try to get available biometrics
      List<BiometricType> availableBio = [];
      try {
        availableBio = await _localAuth.getAvailableBiometrics();
        AppLogger.info('🔐 Biometric: available = $availableBio');
      } catch (e) {
        // Knox blocks this too - assume fingerprint on Samsung
        AppLogger.warn(
            '🔐 Biometric: getAvailableBiometrics blocked (Knox?): $e');
      }

      // Step 4: Determine type
      AppBiometricType type = AppBiometricType.none;
      if (availableBio.contains(BiometricType.face)) {
        type = AppBiometricType.face;
      } else if (availableBio.contains(BiometricType.fingerprint)) {
        type = AppBiometricType.fingerprint;
      } else if (availableBio.contains(BiometricType.iris)) {
        type = AppBiometricType.iris;
      } else if (availableBio.contains(BiometricType.strong) ||
          availableBio.contains(BiometricType.weak)) {
        type = AppBiometricType.fingerprint; // Samsung reports as strong/weak
      } else if (availableBio.isNotEmpty) {
        type = AppBiometricType.multiple;
      } else if (isSupported && canCheck) {
        type = AppBiometricType.fingerprint; // Assume fingerprint on Samsung
      }

      final available =
          isSupported && (canCheck || type != AppBiometricType.none);
      return (available: available, type: type);
    } catch (e) {
      AppLogger.error('🔐 Biometric: Check failed', e);
      return (available: false, type: AppBiometricType.none);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // JWT FETCH
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _fetchJWTFromServer() async {
    try {
      final response = await ApiClient.instance.post(
        '/api/auth/login',
        data: {'method': 'pin', 'pin': _masterPin},
        skipAuth: true,
      );

      if (response.statusCode == 200 && response.data?['token'] != null) {
        final token = response.data['token'] as String;
        const storage = FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );
        await storage.write(key: AppConstants.tokenKey, value: token);
        ApiClient.instance.setCachedToken(token);
        AppLogger.success('🔑 JWT obtained');
      } else {
        AppLogger.warn('🔑 JWT fetch failed: ${response.data}');
      }
    } catch (e) {
      AppLogger.warn('🔑 JWT fetch failed (offline?): $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UNLOCK WITH PIN
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> unlockWithPIN(String pin) async {
    if (state.isLockedOut) {
      AppLogger.warn('🔐 PIN blocked — locked out');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final isValid = await AuthService.verifyPin(pin);

      if (isValid) {
        AppLogger.success('🔐 PIN: Verified ✓');
        await _fetchJWTFromServer();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          isLoading: false,
          failedAttempts: 0,
          clearError: true,
          clearLockout: true,
        );
        return true;
      } else {
        final newAttempts = state.failedAttempts + 1;
        AppLogger.warn('🔐 PIN: Invalid (attempt $newAttempts/$_maxAttempts)');

        if (newAttempts >= _maxAttempts) {
          final lockUntil = DateTime.now().add(_lockoutDuration);
          state = state.copyWith(
            isLoading: false,
            errorType: AuthErrorType.invalidPin,
            errorMessage:
                'Too many attempts. Locked for ${_lockoutDuration.inSeconds}s.',
            failedAttempts: newAttempts,
            lockedUntil: lockUntil,
          );
        } else {
          final remaining = _maxAttempts - newAttempts;
          state = state.copyWith(
            isLoading: false,
            errorType: AuthErrorType.invalidPin,
            errorMessage:
                'Wrong PIN. $remaining attempt${remaining != 1 ? 's' : ''} left.',
            failedAttempts: newAttempts,
          );
        }
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('🔐 PIN error', e, stack);
      state = state.copyWith(isLoading: false, errorType: AuthErrorType.unknown);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UNLOCK WITH BIOMETRIC (Samsung Knox Compatible) — FIXED
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> unlockWithBiometric() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      AppLogger.info('🔐 Biometric: Starting authentication...');

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock KAAPAV',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow device PIN as fallback
          useErrorDialogs: true, // Let OS handle error dialogs
          sensitiveTransaction: false,
        ),
      );

      AppLogger.info('🔐 Biometric: Result = $authenticated');

      if (authenticated) {
        AppLogger.success('🔐 Biometric: Verified ✓');
        await _fetchJWTFromServer();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          isLoading: false,
          failedAttempts: 0,
          clearError: true,
          clearLockout: true,
        );
        return true;
      } else {
        // User cancelled - NOT an error
        AppLogger.info('🔐 Biometric: User cancelled');
        state = state.copyWith(
          isLoading: false,
          errorType: AuthErrorType.biometricCancelled,
        );
        return false;
      }
    } on PlatformException catch (e) {
      AppLogger.error('🔐 Biometric PlatformException: ${e.code} - ${e.message}');

      // ════════════════════════════════════════════════════════════════════════
      // FIX: Don't set error for "too early" exceptions
      // ════════════════════════════════════════════════════════════════════════
      AuthErrorType errorType;
      
      // Common "app not ready" error codes
            if (e.code == 'auth_in_progress') {
        // Platform not ready — treat as silent cancellation
        AppLogger.warn('🔐 Biometric: Platform not ready (${e.code})');
        state = state.copyWith(
          isLoading: false,
          errorType: AuthErrorType.biometricCancelled, // Won't show error
        );
        return false;
      }

      // Actual biometric errors
      switch (e.code) {
        case auth_error.notAvailable:
          errorType = AuthErrorType.biometricNotAvailable;
          break;
        case auth_error.notEnrolled:
          errorType = AuthErrorType.biometricNotEnrolled;
          break;
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          errorType = AuthErrorType.biometricLocked;
          break;
        case auth_error.passcodeNotSet:
          errorType = AuthErrorType.biometricNotAvailable;
          break;
        default:
          // Check if user cancelled
          if (e.message?.toLowerCase().contains('cancel') == true) {
            errorType = AuthErrorType.biometricCancelled;
          } else {
            errorType = AuthErrorType.biometricFailed;
          }
      }

      state = state.copyWith(isLoading: false, errorType: errorType);
      return false;
    } catch (e) {
      AppLogger.error('🔐 Biometric error', e);
      // Generic error — treat as cancellation to avoid scaring users
      state = state.copyWith(
        isLoading: false,
        errorType: AuthErrorType.biometricCancelled,
      );
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ENABLE/DISABLE BIOMETRIC
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> enableBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric for KAAPAV',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        await AuthService.setBiometricEnabled(true);
        final bioResult = await _checkBiometricAvailability();
        state = state.copyWith(
          biometricAvailable: bioResult.available,
          biometricType: bioResult.type,
        );
        AppLogger.success('🔐 Biometric enabled');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('🔐 Enable biometric failed', e);
      return false;
    }
  }

  Future<void> disableBiometric() async {
    await AuthService.setBiometricEnabled(false);
    state = state.copyWith(
      biometricAvailable: false,
      biometricType: AppBiometricType.none,
    );
    AppLogger.info('🔐 Biometric disabled');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PIN MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> setupPIN(String newPin) async {
    try {
      await AuthService.savePin(newPin);
      state = state.copyWith(pinSet: true);
      AppLogger.success('🔐 PIN updated');
      return true;
    } catch (e) {
      AppLogger.error('🔐 PIN setup failed', e);
      return false;
    }
  }

  Future<bool> verifyCurrentPIN(String pin) async {
    return await AuthService.verifyPin(pin);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // LOCK/LOGOUT
  // ─────────────────────────────────────────────────────────────────────────────

  void lockApp() {
    if (state.status == AuthStatus.authenticated) {
      AppLogger.info('🔐 App locked');
      state = state.copyWith(status: AuthStatus.locked, clearError: true);
    }
  }

  Future<void> logout() async {
    AppLogger.info('🔐 Logout');
    state = state.copyWith(status: AuthStatus.locked, clearError: true);
  }

  void resetLockout() {
    if (state.isLockedOut && !DateTime.now().isBefore(state.lockedUntil!)) {
      state = state.copyWith(
          failedAttempts: 0, clearLockout: true, clearError: true);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> recheckBiometrics() async {
    final bioResult = await _checkBiometricAvailability();
    state = state.copyWith(
      biometricAvailable: bioResult.available,
      biometricType: bioResult.type,
    );
  }
}