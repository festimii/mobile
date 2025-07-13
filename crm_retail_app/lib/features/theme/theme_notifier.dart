import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles persisting and toggling the application's theme mode.
class ThemeNotifier extends ChangeNotifier {
  static const _prefKey = 'isDarkMode';

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_prefKey) ?? true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDarkMode);
  }
}
