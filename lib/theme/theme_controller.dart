import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app-wide dark mode preference and persists it locally.
class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'oakshelf_dark_mode';

  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeMode get mode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_prefKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeController: could not load preference: $e');
    }
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (e) {
      debugPrint('ThemeController: could not persist preference: $e');
    }
  }

  void toggle() => setDark(!_isDark);
}
