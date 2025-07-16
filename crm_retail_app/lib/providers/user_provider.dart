import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  static const _key = 'username';

  String _username = '';
  String get username => _username;

  UserProvider() {
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(_key) ?? '';
    notifyListeners();
  }

  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    _username = username;
    await prefs.setString(_key, username);
    notifyListeners();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    _username = '';
    await prefs.remove(_key);
    notifyListeners();
  }
}
