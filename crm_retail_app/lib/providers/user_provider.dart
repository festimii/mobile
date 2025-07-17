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

  /// Clears the stored username. The device token is kept so a trusted
  /// device can still bypass OTP on the next login. Pass `true` to
  /// [removeDeviceToken] to wipe the token as well.
  Future<void> clear({bool removeDeviceToken = false}) async {
    _username = '';
    if (removeDeviceToken) {
      _deviceToken = '';
    }

    try {
      await _secureStorage.delete(key: _keyUsername);
      if (removeDeviceToken) {
        await _secureStorage.delete(key: _keyDeviceToken);
        debugPrint('🧹 [UserProvider] Cleared username and deviceToken');
      } else {
        debugPrint('🧹 [UserProvider] Cleared username');
      }
    } catch (e) {
      debugPrint('❌ [UserProvider] Failed to clear secure storage: $e');
    }

    notifyListeners();
  }
}
