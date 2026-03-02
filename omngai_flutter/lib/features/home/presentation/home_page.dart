import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String msg = "Tap to test API";

  Future<void> testApi() async {
    setState(() => msg = "Testing... (${AppConfig.baseUrl})");

    final res = await DioClient.dio.get("/accounts");

    final status = res.statusCode ?? 0;

    if (status >= 200 && status < 300) {
      setState(() => msg = "✅ OK ($status)\n${res.data}");
    } else {
      setState(() => msg = "⚠️ Not OK ($status)\n${res.data}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OmNgai Flutter")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: testApi,
            child: Text(msg, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
