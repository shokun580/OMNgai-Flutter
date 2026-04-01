import 'package:flutter_dotenv/flutter_dotenv.dart';

// รวมค่าคอนฟิกของแอปที่ต้องอ่านจาก environment
class AppConfig {
  static String get baseUrl {
    // ถ้าไม่ได้ตั้งค่าใน .env จะ fallback ไปใช้ backend ตัวหลัก
    final url = dotenv.maybeGet('API_BASE_URL');
    return (url != null && url.isNotEmpty)
        ? url
        : "https://omngai.onrender.com";
  }
}
