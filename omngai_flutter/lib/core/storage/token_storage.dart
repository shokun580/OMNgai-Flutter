import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ห่อการใช้งาน secure storage ไว้ที่เดียวสำหรับข้อมูล session
class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _kToken = 'token';
  static const _kUserId = 'userId';

  // เก็บ access token ที่ได้จาก backend หลัง login สำเร็จ
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _kToken, value: token);
  }

  // อ่าน token ปัจจุบันเพื่อนำไปแนบใน request ถัด ๆ ไป
  static Future<String?> getToken() async {
    return await _storage.read(key: _kToken);
  }

  // เก็บ userId แยกไว้เพื่อใช้ดึงข้อมูลบัญชีและทำรายการ
  static Future<void> saveUserId(int userId) async {
    await _storage.write(key: _kUserId, value: userId.toString());
  }

  // แปลงค่าที่อ่านจาก storage ให้กลับมาเป็น int อย่างปลอดภัย
  static Future<int?> getUserId() async {
    final value = await _storage.read(key: _kUserId);
    if (value == null) return null;
    return int.tryParse(value);
  }

  // ลบข้อมูล session ทั้งหมดตอน logout
  static Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUserId);
  }
}
