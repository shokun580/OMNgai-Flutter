import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

// สร้าง Dio กลางของแอปเพื่อให้ทุก feature ใช้ config ชุดเดียวกัน
class DioClient {
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {"Content-Type": "application/json"},

            // ให้ Dio ส่ง response กลับมาแม้ status จะไม่ใช่ 2xx
            // เพื่อให้ UI จัดการข้อความ error ได้จากข้อมูล response จริง
            validateStatus: (status) {
              return status != null && status < 600;
            },
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              // แนบ token อัตโนมัติทุกครั้งถ้ามี session อยู่
              final token = await TokenStorage.getToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              print("➡️ REQUEST: ${options.method} ${options.path}");
              handler.next(options);
            },
            onResponse: (response, handler) {
              // log response ไว้ช่วย debug flow API ระหว่างพัฒนา
              print(
                "✅ RESPONSE [${response.statusCode}]: ${response.requestOptions.path}",
              );
              handler.next(response);
            },
            onError: (DioException e, handler) {
              // log error network-level เช่น timeout หรือ socket exception
              print(
                "❌ ERROR [${e.response?.statusCode}]: ${e.requestOptions.path}",
              );
              handler.next(e);
            },
          ),
        );
}
