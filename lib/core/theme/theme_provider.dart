import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  final Box _appDataBox;

  ThemeProvider({required Box appBox}) : _appDataBox = appBox {
    _loadThemeMode();
  }

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Whether current active mode is dark based on toggle and system brightness
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void _loadThemeMode() {
    final savedValue = _appDataBox.get(_themeModeKey);
    if (savedValue is String) {
      switch (savedValue) {
        case 'dark':
          _themeMode = ThemeMode.dark;
          return;
        case 'light':
          _themeMode = ThemeMode.light;
          return;
        case 'system':
          _themeMode = ThemeMode.system;
          return;
      }
    }

    // Backward compatibility for older persisted formats.
    if (savedValue is bool) {
      _themeMode = savedValue ? ThemeMode.dark : ThemeMode.light;
      return;
    }
    if (savedValue is int && savedValue >= 0 && savedValue < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[savedValue];
      return;
    }

    _themeMode = ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final encoded = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await _appDataBox.put(_themeModeKey, encoded);
    notifyListeners();
  }

  // Toggle dark mode (true = dark, false = light)
  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
