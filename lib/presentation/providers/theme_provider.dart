import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light
            ? 'light'
            : 'system');
  }

  Future<void> toggleDark() async {
    await setTheme(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  String get displayName {
    switch (_themeMode) {
      case ThemeMode.dark:   return 'Dark';
      case ThemeMode.light:  return 'Light';
      default:               return 'System Default';
    }
  }

  // --- Experimental: Mood Themes ---
  Color _moodColor = Colors.transparent;
  Color get moodColor => _moodColor;

  void updateThemeBasedOnMood(String emoji) {
    Color newColor;
    switch (emoji) {
      case '🔥': newColor = Colors.orangeAccent; break;
      case '😊': newColor = Colors.amber; break;
      case '😐': newColor = Colors.transparent; break;
      case '😟': newColor = Colors.blueGrey; break;
      case '😠': newColor = Colors.redAccent; break;
      default: newColor = Colors.transparent;
    }
    
    if (_moodColor != newColor) {
      _moodColor = newColor;
      notifyListeners();
    }
  }
}
