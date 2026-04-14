import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricService {
  static final BiometricService instance = 
      BiometricService._internal();
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Prompt the device biometric dialog.
  /// Returns true if authenticated successfully.
  Future<BiometricResult> authenticate({
    String reason = 'Confirm your identity',
  }) async {
    final available = await isAvailable();
    if (!available) {
      return BiometricResult(
        success: false,
        message: 'Biometrics not available on this device',
        notAvailable: true,
      );
    }

    try {
      final didAuth = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth:   true,
          biometricOnly: false,  // allow PIN fallback
          useErrorDialogs: true,
        ),
      );

      return BiometricResult(
        success: didAuth,
        message: didAuth
            ? 'Authenticated successfully'
            : 'Authentication failed',
      );

    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        return BiometricResult(
          success:      false,
          message:      'Biometrics not enrolled on this device',
          notAvailable: true,
        );
      }
      if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return BiometricResult(
          success: false,
          message: 'Too many attempts — device locked',
        );
      }
      return BiometricResult(
        success: false,
        message: 'Authentication error: ${e.message}',
      );
    }
  }
}

class BiometricResult {
  final bool success;
  final String message;
  final bool notAvailable;

  BiometricResult({
    required this.success,
    required this.message,
    this.notAvailable = false,
  });
}
