import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';

class ActionPage extends StatefulWidget {
  final bool isDeposit;
  const ActionPage({super.key, required this.isDeposit});

  @override
  State<ActionPage> createState() => _ActionPageState();
}

class _ActionPageState extends State<ActionPage> {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  String msg = "";
  bool loading = false;

  Future<void> submit() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) {
      setState(() => msg = "❌ ไม่เจอ userId (ลอง logout/login ใหม่)");
      return;
    }

    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => msg = "❌ Amount ต้องเป็นตัวเลขมากกว่า 0");
      return;
    }

    final signedAmount = widget.isDeposit ? amount : -amount;
    final note = noteCtrl.text.trim().isEmpty
        ? (widget.isDeposit ? "ฝากเงิน" : "ถอนเงิน")
        : noteCtrl.text.trim();

    setState(() {
      loading = true;
      msg = "⏳ กำลังทำรายการ...";
    });

    try {
      final res = await DioClient.dio.post(
        "/action",
        data: {"user_id": userId, "amount": signedAmount, "note": note},
      );

      final status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        setState(() => msg = "✅ สำเร็จ");
        if (mounted) Navigator.pop(context); // ✅ ทำเสร็จเด้งกลับ Home
      } else {
        setState(() => msg = "⚠️ ไม่สำเร็จ ($status)\n${res.data}");
      }
    } catch (e) {
      setState(() => msg = "❌ Error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isDeposit ? "ฝากเงิน" : "ถอนเงิน")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                hintText: "เช่น 1000",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: "Note (optional)",
                hintText: "เช่น ฝากเงินเดือน",
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : submit,
              child: Text(
                loading
                    ? "..."
                    : (widget.isDeposit ? "ยืนยันฝาก" : "ยืนยันถอน"),
              ),
            ),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
