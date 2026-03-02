import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _kToken = 'token';
  static const _kUserId = 'userId';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _kToken, value: token);

  static Future<String?> getToken() =>
      _storage.read(key: _kToken);

  static Future<void> saveUserId(String userId) =>
      _storage.write(key: _kUserId, value: userId);

  static Future<String?> getUserId() =>
      _storage.read(key: _kUserId);

  static Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUserId);
  }
}