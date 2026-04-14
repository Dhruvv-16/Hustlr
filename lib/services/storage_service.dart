import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for auth, onboarding, and profile fields.
/// Keeps static accessors (used by [MockDataService], [AuthService]) in sync with instance helpers.
class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyIsOnboardedLegacy = 'isOnboarded';
  static const _keyHasSeenCarousel = 'hasSeenCarousel';
  static const _keyPhone = 'phone';
  static const _keyUserId = 'userId';
  static const _keyPolicyId = 'policyId';
  static const _keyUserZone = 'userZone';
  static const _keyOnboardingComplete = 'onboardingComplete';
  static const _keyShiftActive = 'shiftActive';
  static const _keyShiftZone = 'shiftZone';

  // ── Static sync API (after [init]) ─────────────────────────────────────────
  static bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  static bool get isOnboarded =>
      _prefs.getBool(_keyOnboardingComplete) ??
      _prefs.getBool(_keyIsOnboardedLegacy) ??
      false;
  static bool get hasSeenCarousel =>
      _prefs.getBool(_keyHasSeenCarousel) ?? false;
  static String get phone => _prefs.getString(_keyPhone) ?? '';
  static String get userId => _prefs.getString(_keyUserId) ?? '';
  static String get policyId => _prefs.getString(_keyPolicyId) ?? '';
  static String get userZone => _prefs.getString(_keyUserZone) ?? '';
  static bool get shiftActive => _prefs.getBool(_keyShiftActive) ?? false;
  static String get shiftZone => _prefs.getString(_keyShiftZone) ?? '';

  static Future<void> setLoggedIn(bool v) => _prefs.setBool(_keyIsLoggedIn, v);
  static Future<void> setOnboarded(bool v) async {
    await _prefs.setBool(_keyOnboardingComplete, v);
    await _prefs.setBool(_keyIsOnboardedLegacy, v);
  }

  static Future<void> setHasSeenCarousel(bool v) =>
      _prefs.setBool(_keyHasSeenCarousel, v);
  static Future<void> setPhone(String v) => _prefs.setString(_keyPhone, v);
  static Future<void> setUserId(String v) =>
      _prefs.setString(_keyUserId, v);
  static Future<void> setPolicyId(String v) =>
      _prefs.setString(_keyPolicyId, v);
  static Future<void> setUserZone(String v) =>
      _prefs.setString(_keyUserZone, v);
  static Future<void> setShiftActive(bool v) =>
      _prefs.setBool(_keyShiftActive, v);
  static Future<void> setShiftZone(String v) =>
      _prefs.setString(_keyShiftZone, v);
  static Future<void> clearAll() => _prefs.clear();

  static Future<void> setBool(String key, bool value) =>
      _prefs.setBool(key, value);
  static Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  static Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
      
  static bool? getBool(String key) => _prefs.getBool(key);
  static String? getString(String key) => _prefs.getString(key);
  static double? getDouble(String key) => _prefs.getDouble(key);

  // ── Instance API (prompt / async) ───────────────────────────────────────
  Future<void> savePhone(String phone) async => setPhone(phone);

  Future<String?> getPhone() async =>
      phone.isEmpty ? null : phone;

  Future<void> saveUserId(String id) async => setUserId(id);

  Future<String?> getUserId() async =>
      userId.isEmpty ? null : userId;

  Future<void> savePolicyId(String id) async => setPolicyId(id);

  Future<String?> getPolicyId() async =>
      policyId.isEmpty ? null : policyId;

  Future<void> saveUserName(String name) async =>
      setString('userName', name);

  Future<String?> getUserName() async => getString('userName');

  Future<void> saveUserZone(String zone) async => setUserZone(zone);

  Future<String?> getUserZone() async =>
      userZone.isEmpty ? null : userZone;

  Future<void> setShiftTrackingActive(bool value) async => setShiftActive(value);
  Future<bool> isShiftTrackingActive() async => shiftActive;
  Future<void> saveShiftZone(String zone) async => setShiftZone(zone);
  Future<String?> getShiftZone() async => shiftZone.isEmpty ? null : shiftZone;

  Future<void> saveUserCity(String city) async =>
      setString('userCity', city);

  Future<String?> getUserCity() async => getString('userCity');

  Future<void> setOnboardingComplete(bool value) async => setOnboarded(value);

  Future<bool> isOnboardingComplete() async => isOnboarded;

  Future<void> clearDemoState() async {
    // Implement any demo specific clearing if necessary
  }

  Future<void> setLastLat(double lat) async => setDouble('lastLat', lat);
  Future<void> setLastLng(double lng) async => setDouble('lastLng', lng);
  Future<void> setPlanTier(String tier) async => setString('planTier', tier);
  Future<void> setWeeklyPremium(double premium) async => setDouble('weeklyPremium', premium);
}
