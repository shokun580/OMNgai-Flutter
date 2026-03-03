import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _kToken = 'token';
  static const _kUserId = 'userId';

  // ---------------- TOKEN ----------------
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _kToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _kToken);
  }

  // ---------------- USER ID ----------------
  static Future<void> saveUserId(int userId) async {
    await _storage.write(key: _kUserId, value: userId.toString());
  }

  static Future<int?> getUserId() async {
    final value = await _storage.read(key: _kUserId);
    if (value == null) return null;
    return int.tryParse(value);
  }

  // ---------------- CLEAR ----------------
  static Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUserId);
  }
}
