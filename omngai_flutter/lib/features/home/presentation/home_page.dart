import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/presentation/login_page.dart';
import '../../transactions/presentation/action_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? userId;

  bool loading = true;
  String? error;

  Map<String, dynamic>? account; // ✅ เหลือบัญชีเดียว
  bool txLoading = true;
  String? txError;
  List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    userId = await TokenStorage.getUserId();

    if (userId == null) {
      await logout(); // ถ้าไม่มี userId ให้กลับไป login
      return;
    }

    await Future.wait([loadAccount(), loadTransactions()]);
  }

  // ✅ ดึงบัญชีของ user คนนี้เท่านั้น (ไม่แก้ backend)
  Future<void> loadAccount() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final uid = userId;
      if (uid == null) {
        setState(() {
          error = "ไม่พบ userId (ลอง logout/login ใหม่)";
          loading = false;
        });
        return;
      }

      final res = await DioClient.dio.get("/accounts/$uid");
      final status = res.statusCode ?? 0;

      if (status >= 200 && status < 300) {
        final data = res.data;

        Map<String, dynamic>? parsedAccount;

        // backend อาจส่งมาเป็น list หรือ object
        if (data is List && data.isNotEmpty && data.first is Map) {
          parsedAccount = Map<String, dynamic>.from(data.first);
        } else if (data is Map) {
          final map = Map<String, dynamic>.from(data);

          // เผื่อ backend wrap มาเป็น { accounts: [..] } / { data: [..] }
          if (map["accounts"] is List && (map["accounts"] as List).isNotEmpty) {
            final first = (map["accounts"] as List).first;
            if (first is Map) parsedAccount = Map<String, dynamic>.from(first);
          } else if (map["data"] is List && (map["data"] as List).isNotEmpty) {
            final first = (map["data"] as List).first;
            if (first is Map) parsedAccount = Map<String, dynamic>.from(first);
          } else {
            // หรือเป็น account object ตรง ๆ
            parsedAccount = map;
          }
        }

        setState(() {
          account = parsedAccount;
          loading = false;
        });
      } else {
        setState(() {
          error = "Load account failed ($status)\n${res.data}";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Network error (account): $e";
        loading = false;
      });
    }
  }

  Future<void> loadTransactions() async {
    setState(() {
      txLoading = true;
      txError = null;
    });

    try {
      final uid = userId ?? await TokenStorage.getUserId();
      if (uid == null) {
        setState(() {
          txError = "ไม่พบ userId (ลอง logout/login ใหม่)";
          txLoading = false;
        });
        return;
      }

      final res = await DioClient.dio.get("/transactions/$uid");
      final status = res.statusCode ?? 0;

      if (status >= 200 && status < 300) {
        final data = res.data;

        // ✅ backend ส่งรูปแบบ { message, data: [...] }
        List<dynamic> list = [];
        if (data is Map && data["data"] is List) {
          list = List<dynamic>.from(data["data"]);
        } else if (data is List) {
          list = data;
        }

        setState(() {
          transactions = list;
          txLoading = false;
        });
      } else {
        setState(() {
          txError = "Load transactions failed ($status)\n${res.data}";
          txLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        txError = "Network error (transactions): $e";
        txLoading = false;
      });
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> goAction(bool isDeposit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActionPage(isDeposit: isDeposit)),
    );

    // กลับมาแล้ว refresh
    await Future.wait([loadAccount(), loadTransactions()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OmNgai Flutter"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await Future.wait([loadAccount(), loadTransactions()]);
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(error!, textAlign: TextAlign.center),
              ),
            )
          : Column(
              children: [
                // ✅ ปุ่ม ฝาก / ถอน
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => goAction(true),
                          child: const Text("ฝาก"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => goAction(false),
                          child: const Text("ถอน"),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([loadAccount(), loadTransactions()]);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text("Account"),
                        ),

                        if (account == null)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("No account"),
                          )
                        else
                          ListTile(
                            title: Text(account!["ac_no"]?.toString() ?? "-"),
                            subtitle: Text(
                              "Balance: ${account!["ac_balance"]?.toString() ?? "0"}",
                            ),
                          ),

                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text("Transactions"),
                        ),

                        if (txLoading)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (txError != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(txError!),
                          )
                        else if (transactions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("No transactions"),
                          )
                        else
                          ...transactions.map((t) {
                            if (t is! Map) {
                              return ListTile(
                                title: const Text("Transaction"),
                                subtitle: Text(t.toString()),
                              );
                            }

                            final tx = Map<String, dynamic>.from(t);

                            // ✅ key ตรง backend
                            final note =
                                tx["ts_note"]?.toString().trim().isNotEmpty ==
                                    true
                                ? tx["ts_note"].toString()
                                : "-";
                            final amountNum =
                                double.tryParse(
                                  tx["ts_amount"]?.toString() ?? "0",
                                ) ??
                                0;
                            final txId = tx["ts_id"]?.toString() ?? "";
                            final acNo = tx["ac_no"]?.toString() ?? "";

                            final isDeposit = amountNum >= 0;

                            return ListTile(
                              title: Text(note),
                              subtitle: Text(
                                [
                                  if (acNo.isNotEmpty) "AC: $acNo",
                                  if (txId.isNotEmpty) "TX: $txId",
                                ].join(" • "),
                              ),
                              trailing: Text(
                                "${isDeposit ? "+" : ""}${amountNum.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDeposit ? Colors.green : Colors.red,
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
