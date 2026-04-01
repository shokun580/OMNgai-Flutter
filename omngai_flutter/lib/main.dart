import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_page.dart';

// Bootstrap แอปและพยายามโหลดค่าจาก .env ก่อนเริ่ม render UI
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  runApp(const MyApp());
}

// Root widget ของแอป ใช้ตัดสินใจว่าจะเริ่มที่หน้า login หรือ home
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _startPage;

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {
    // ถ้ามี token ค้างอยู่ ให้ข้ามหน้า login ไปหน้า home ได้เลย
    final token = await TokenStorage.getToken();
    setState(() {
      _startPage = (token != null && token.isNotEmpty)
          ? const HomePage()
          : const LoginPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ระหว่างเช็ก token แสดง loading กลางหน้าจอไว้ก่อน
    if (_startPage == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(debugShowCheckedModeBanner: false, home: _startPage!);
  }
}
