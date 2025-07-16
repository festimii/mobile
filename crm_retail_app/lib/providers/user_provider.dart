import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  static const _keyUsername = 'username';
  static const _keyDeviceToken = 'device_token';

  String _username = '';
  String _deviceToken = '';
  String get username => _username;
  String get deviceToken => _deviceToken;

  UserProvider() {
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(_keyUsername) ?? '';
    _deviceToken = prefs.getString(_keyDeviceToken) ?? '';
    notifyListeners();
  }

  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    _username = username;
    await prefs.setString(_keyUsername, username);
    notifyListeners();
  }

  Future<void> setDeviceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    _deviceToken = token;
    await prefs.setString(_keyDeviceToken, token);
    notifyListeners();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    _username = '';
    _deviceToken = '';
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyDeviceToken);
    notifyListeners();
  }
}
