import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences with typed helpers.
class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────
  static const _keyIsLoggedIn   = 'isLoggedIn';
  static const _keyIsOnboarded  = 'isOnboarded';
  static const _keyPhone        = 'phone';
  static const _keyUserId       = 'userId';

  static bool   get isLoggedIn   => _prefs.getBool(_keyIsLoggedIn)   ?? false;
  static bool   get isOnboarded  => _prefs.getBool(_keyIsOnboarded)  ?? false;
  static String get phone        => _prefs.getString(_keyPhone)      ?? '';
  static String get userId       => _prefs.getString(_keyUserId)     ?? '';

  static Future<void> setLoggedIn(bool v)  => _prefs.setBool(_keyIsLoggedIn,  v);
  static Future<void> setOnboarded(bool v) => _prefs.setBool(_keyIsOnboarded, v);
  static Future<void> setPhone(String v)   => _prefs.setString(_keyPhone,     v);
  static Future<void> setUserId(String v)  => _prefs.setString(_keyUserId,    v);

  static Future<void> clearAll() => _prefs.clear();

  // ─── Generic helpers ───────────────────────────────────────────────────────
  static Future<void> setBool(String key, bool value)     => _prefs.setBool(key, value);
  static Future<void> setString(String key, String value) => _prefs.setString(key, value);
  static bool?   getBool(String key)   => _prefs.getBool(key);
  static String? getString(String key) => _prefs.getString(key);
}
