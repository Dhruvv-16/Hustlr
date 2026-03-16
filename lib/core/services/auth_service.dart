import 'storage_service.dart';

/// Stub auth service. Replace with real API / Firebase Auth later.
class AuthService {
  AuthService._();

  static bool get isLoggedIn  => StorageService.isLoggedIn;
  static bool get isOnboarded => StorageService.isOnboarded;
  static String get userId    => StorageService.userId;
  static String get phone     => StorageService.phone;

  /// Simulates sending OTP (stub – just stores phone).
  static Future<void> sendOtp(String phone) async {
    await StorageService.setPhone(phone);
  }

  /// Simulates verifying OTP (stub – any 6-digit code succeeds).
  static Future<bool> verifyOtp(String otp) async {
    if (otp.length == 6) {
      await StorageService.setLoggedIn(true);
      await StorageService.setUserId('user_${DateTime.now().millisecondsSinceEpoch}');
      return true;
    }
    return false;
  }

  /// Called once onboarding questionnaire is complete.
  static Future<void> completeOnboarding() async {
    await StorageService.setOnboarded(true);
  }

  static Future<void> logout() async {
    await StorageService.clearAll();
  }
}
