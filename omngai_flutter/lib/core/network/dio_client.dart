import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},

      // 👇 เพิ่มตรงนี้
      validateStatus: (status) {
        return status != null && status < 600;
      },
    ),
  )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print("➡️ REQUEST: ${options.method} ${options.path}");
          handler.next(options);
        },
        onResponse: (response, handler) {
          print("✅ RESPONSE [${response.statusCode}]: ${response.requestOptions.path}");
          handler.next(response);
        },
        onError: (DioException e, handler) {
          print("❌ ERROR [${e.response?.statusCode}]: ${e.requestOptions.path}");
          handler.next(e);
        },
      ),
    );
}