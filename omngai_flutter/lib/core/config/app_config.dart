import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    final url = dotenv.maybeGet('API_BASE_URL');
    return (url != null && url.isNotEmpty) ? url : "http://localhost:3000";
  }
}