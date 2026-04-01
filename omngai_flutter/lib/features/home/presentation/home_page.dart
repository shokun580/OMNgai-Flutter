import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/presentation/login_page.dart';
import '../../transactions/presentation/action_page.dart';

// หน้า dashboard หลัก แสดงข้อมูลบัญชีและรายการเดินบัญชีของผู้ใช้
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  int? userId;

  bool loading = true;
  String? error;

  Map<String, dynamic>? account;
  bool txLoading = true;
  String? txError;
  List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลที่ต้องใช้ทั้งหมดทันทีเมื่อเข้าหน้า home
    initData();
  }

  Future<void> initData() async {
    userId = await TokenStorage.getUserId();

    if (userId == null) {
      // ถ้า session ไม่สมบูรณ์ให้บังคับกลับไป login ใหม่
      await logout();
      return;
    }

    await Future.wait([loadAccount(), loadTransactions()]);
  }

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

        // รองรับ response ได้หลายรูปแบบตาม backend ที่ส่งกลับมา
        if (data is List && data.isNotEmpty && data.first is Map) {
          parsedAccount = Map<String, dynamic>.from(data.first);
        } else if (data is Map) {
          final map = Map<String, dynamic>.from(data);

          if (map["accounts"] is List && (map["accounts"] as List).isNotEmpty) {
            final first = (map["accounts"] as List).first;
            if (first is Map) parsedAccount = Map<String, dynamic>.from(first);
          } else if (map["data"] is List && (map["data"] as List).isNotEmpty) {
            final first = (map["data"] as List).first;
            if (first is Map) parsedAccount = Map<String, dynamic>.from(first);
          } else {
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

        List<dynamic> list = [];
        // รองรับทั้ง response ที่เป็น list ตรง ๆ และแบบห่อไว้ใน data
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
    // ล้าง session แล้ว reset navigation stack กลับไปหน้า login
    await TokenStorage.clear();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _onTabTapped(int index) {
    // แท็บล่าง 2 อันหลังทำหน้าที่เปิด flow ฝาก/ถอนแทนการสลับหน้า
    if (index == 1) {
      _goAction(true);
    } else if (index == 2) {
      _goAction(false);
    } else {
      setState(() => _currentIndex = 0);
    }
  }

  Future<void> _goAction(bool isDeposit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActionPage(isDeposit: isDeposit)),
    );

    // เมื่อกลับจากหน้าทำรายการ ให้รีโหลดข้อมูลล่าสุดแล้วชี้กลับแท็บบัญชี
    setState(() => _currentIndex = 0);
    await Future.wait([loadAccount(), loadTransactions()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(error!, textAlign: TextAlign.center),
                ),
              )
            : _buildAccountBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
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

  Widget _buildAccountBody() {
    final acNo = account?["ac_no"]?.toString() ?? "-";
    final balance = account?["ac_balance"]?.toString() ?? "0";
    // บังคับรูปแบบยอดเงินให้แสดงทศนิยม 2 ตำแหน่งเสมอ
    final balanceNum = double.tryParse(balance) ?? 0;
    final balanceStr = balanceNum.toStringAsFixed(2);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([loadAccount(), loadTransactions()]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 16),

          // ส่วนหัวพร้อมปุ่ม refresh และ logout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OmNgai',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.black54),
                    onPressed: () async {
                      await Future.wait([loadAccount(), loadTransactions()]);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: logout,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // การ์ดสรุปเลขบัญชีและยอดเงินปัจจุบัน
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5CB85C), Color(0xFF94CD7E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อหัวข้อและเลขบัญชี
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          acNo,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    // ไอคอนตกแต่งของการ์ดบัญชี
                    const Icon(Icons.savings, size: 70, color: Colors.white),
                  ],
                ),

                const SizedBox(height: 16),

                // กล่องแสดงยอดคงเหลือ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Balance : $balanceStr',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ปุ่มลัดสำหรับเปิดหน้าฝากหรือถอนเงิน
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goAction(true),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'ฝาก',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goAction(false),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'ถอน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // หัวข้อของรายการเคลื่อนไหวบัญชี
          const Text(
            'Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          // สลับสถานะระหว่าง loading, error, empty state และ list จริง
          if (txLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (txError != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(txError!))
          else if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No transactions"),
            )
          else
            ...transactions.map((t) {
              if (t is! Map) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTxCard("Transaction", t.toString(), "", 0),
                );
              }

              final tx = Map<String, dynamic>.from(t);

              final note = tx["ts_note"]?.toString().trim().isNotEmpty == true
                  ? tx["ts_note"].toString()
                  : "-";
              final amountNum =
                  double.tryParse(tx["ts_amount"]?.toString() ?? "0") ?? 0;
              final txId = tx["ts_id"]?.toString() ?? "";
              final acNo = tx["ac_no"]?.toString() ?? "";

              // รวมข้อมูลอ้างอิงที่มีอยู่ให้แสดงในบรรทัดรองของการ์ด
              final subtitle = [
                if (acNo.isNotEmpty) "AC: $acNo",
                if (txId.isNotEmpty) "TX: $txId",
              ].join(" ");

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTxCard(note, subtitle, "", amountNum),
              );
            }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTxCard(
    String title,
    String subtitle,
    String trailing,
    double amount,
  ) {
    final isDeposit = amount >= 0;
    final amountStr = "${isDeposit ? "+" : ""}${amount.toStringAsFixed(2)}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ฝั่งซ้ายใช้แสดงชื่อรายการและรายละเอียดอ้างอิง
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
          // ฝั่งขวาใช้สีเพื่อแยกฝากเงินกับถอนเงิน
          Text(
            amountStr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDeposit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
