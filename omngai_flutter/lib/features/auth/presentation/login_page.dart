import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../home/presentation/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String msg = "";
  bool loading = false;

  Future<void> login() async {
    setState(() {
      loading = true;
      msg = "Logging in...";
    });

    try {
      final res = await DioClient.dio.post(
        "/login",
        data: {
          "username": usernameController.text.trim(),
          "password": passwordController.text.trim(),
        },
      );

      if (res.statusCode == 200 && res.data["token"] != null) {
        await TokenStorage.saveToken(res.data["token"]);
        await TokenStorage.saveUserId("${res.data["user"]["id"]}");

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        setState(() => msg = "❌ Login failed (${res.statusCode})");
      }
    } catch (e) {
      setState(() => msg = "❌ Error: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : login,
              child: Text(loading ? "Loading..." : "Login"),
            ),
            const SizedBox(height: 12),
            Text(msg),
          ],
        ),
      ),
    );
  }
}