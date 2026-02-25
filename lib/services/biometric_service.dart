import 'package:local_auth/local_auth.dart';
import '../utils/logger.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      Logger.error('Biometric availability check failed', e);
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      Logger.error('Get biometric types failed', e);
      return [];
    }
  }

  /// Check if fingerprint is available
  static Future<bool> hasFingerprint() async {
    final types = await getAvailableTypes();
    return types.contains(BiometricType.fingerprint);
  }

  /// Check if face ID is available
  static Future<bool> hasFaceId() async {
    final types = await getAvailableTypes();
    return types.contains(BiometricType.face);
  }

  /// Authenticate with biometric
  static Future<bool> authenticate({
    String reason = 'Verify your identity to access KAAPAV',
  }) async {
    try {
      final isAvail = await isAvailable();
      if (!isAvail) {
        Logger.warn('Biometric not available');
        return false;
      }

      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern fallback
          useErrorDialogs: true,
        ),
      );

      Logger.auth('Biometric auth: ${result ? "success" : "failed"}');
      return result;
    } catch (e) {
      Logger.error('Biometric auth failed', e);
      return false;
    }
  }

  /// Get biometric type label
  static Future<String> getBiometricLabel() async {
    final types = await getAvailableTypes();
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }
}