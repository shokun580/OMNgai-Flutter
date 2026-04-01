import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../home/presentation/home_page.dart';

// หน้า login สำหรับรับ credential และสร้าง session ของผู้ใช้
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String msg = "";
  bool loading = false;

  bool get _isFormFilled =>
      emailController.text.trim().isNotEmpty &&
      passwordController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // อัปเดตสถานะปุ่ม login แบบ real-time เมื่อมีการพิมพ์ข้อมูล
    emailController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
  }

  Future<void> login() async {
    setState(() {
      loading = true;
      msg = "Logging in...";
    });

    try {
      // backend ใช้ key เป็น username แม้ UI จะเรียก field นี้ว่า email/username
      final res = await DioClient.dio.post(
        "/login",
        data: {
          "username": emailController.text.trim(),
          "password": passwordController.text.trim(),
        },
      );

      final status = res.statusCode ?? 0;

      if (status == 200 && res.data["token"] != null) {
        final token = res.data["token"] as String;

        // รองรับกรณี id จาก API อาจมาเป็น int หรือ string
        final userIdDynamic = res.data["user"]?["id"];
        final userId = (userIdDynamic is int)
            ? userIdDynamic
            : int.tryParse(userIdDynamic?.toString() ?? "");

        if (userId == null) {
          setState(() => msg = "❌ Login failed: userId not found");
          return;
        }

        await TokenStorage.saveToken(token);
        await TokenStorage.saveUserId(userId);

        // เปลี่ยน route หลัง login สำเร็จเพื่อไม่ให้กดย้อนกลับมาหน้าเดิม
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        setState(() => msg = "❌ Login failed ($status)");
      }
    } catch (e) {
      setState(() => msg = "❌ Error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isFormFilled;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // ส่วนหัวของหน้า login
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 30),

              // โลโก้ของแอป
              Image.asset('assets/images/image 5.png', height: 180),

              const SizedBox(height: 40),

              // ช่องกรอก username
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: const Color(0xFF94CD7E),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ช่องกรอกรหัสผ่าน
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.vpn_key_outlined,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: const Color(0xFF94CD7E),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ปุ่มจะกดได้เมื่อกรอกข้อมูลครบและไม่ได้อยู่ระหว่างส่ง request
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (loading || !isActive) ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? const Color(0xFF94CD7E)
                        : Colors.grey.shade400,
                    disabledBackgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    loading ? 'Loading...' : 'Login',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // แสดงสถานะหรือข้อความผิดพลาดจากการ login
              if (msg.isNotEmpty)
                Text(msg, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
