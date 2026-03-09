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
        if (mounted) Navigator.pop(context);
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
    final accentColor =
        widget.isDeposit ? const Color(0xFF94CD7E) : Colors.red;
    final title = widget.isDeposit ? 'ฝากเงิน' : 'ถอนเงิน';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // ── Form Card ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount label
                      const Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Amount field
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide:
                                BorderSide(color: accentColor, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Note label
                      const Text(
                        'Note (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Note field (multiline)
                      TextField(
                        controller: noteCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Note (Optional)',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: accentColor, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            disabledBackgroundColor:
                                accentColor.withValues(alpha: 0.5),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            loading ? '...' : 'ยืนยัน',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Message
                      if (msg.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          msg,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.isDeposit ? 1 : 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1 && !widget.isDeposit) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ActionPage(isDeposit: true),
              ),
            );
          } else if (index == 2 && widget.isDeposit) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ActionPage(isDeposit: false),
              ),
            );
          }
        },
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFF2E7D6F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'บัญชี',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'ฝากเงิน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_circle_outline),
            activeIcon: Icon(Icons.remove_circle),
            label: 'ถอนเงิน',
          ),
        ],
      ),
    );
  }
}
