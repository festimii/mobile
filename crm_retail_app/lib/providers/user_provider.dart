import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProvider with ChangeNotifier {
  static const _keyUsername = 'username';
  static const _keyDeviceToken = 'device_token';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _username = '';
  String _deviceToken = '';

  String get username => _username;
  String get deviceToken => _deviceToken;

  /// Initializes from secure storage
  Future<void> init() async {
    try {
      _username = await _secureStorage.read(key: _keyUsername) ?? '';
      _deviceToken = await _secureStorage.read(key: _keyDeviceToken) ?? '';
      debugPrint('📦 [UserProvider.init] Loaded username: $_username');
      debugPrint('📦 [UserProvider.init] Loaded deviceToken: $_deviceToken');
    } catch (e) {
      debugPrint('❌ [UserProvider.init] Failed to read secure storage: $e');
    }
    notifyListeners();
  }

  Future<void> setUsername(String username) async {
    _username = username;
    try {
      await _secureStorage.write(key: _keyUsername, value: username);
      debugPrint('✅ [UserProvider] Saved username: $_username');
    } catch (e) {
      debugPrint('❌ [UserProvider] Failed to save username: $e');
    }
    notifyListeners();
  }

  Future<void> setDeviceToken(String token) async {
    _deviceToken = token;
    try {
      await _secureStorage.write(key: _keyDeviceToken, value: token);
      debugPrint('✅ [UserProvider] Saved deviceToken: $_deviceToken');
    } catch (e) {
      debugPrint('❌ [UserProvider] Failed to save deviceToken: $e');
    }
    notifyListeners();
  }

  Future<void> clear() async {
    _username = '';
    _deviceToken = '';
    try {
      await _secureStorage.delete(key: _keyUsername);
      await _secureStorage.delete(key: _keyDeviceToken);
      debugPrint('🧹 [UserProvider] Cleared username and deviceToken');
    } catch (e) {
      debugPrint('❌ [UserProvider] Failed to clear secure storage: $e');
    }
    notifyListeners();
  }

  /// Clears only the persisted username. The device token is preserved so the
  /// device remains trusted for future logins.
  Future<void> logout() async {
    _username = '';
    try {
      await _secureStorage.delete(key: _keyUsername);
      debugPrint('🧹 [UserProvider] Cleared username');
    } catch (e) {
      debugPrint('❌ [UserProvider] Failed to clear username: $e');
    }
    notifyListeners();
  }
}
