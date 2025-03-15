// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:money_gets_money/services/database_services.dart';
import 'package:money_gets_money/widgets/dashboard_widget.dart';

import 'income_page.dart';
import 'expense_page.dart';
import 'debt_page.dart';
import 'available_balance_page.dart';
import 'total_page.dart';
import 'add_new_expanse_page.dart';
import 'edit_expanse_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DatabaseService _dbService = DatabaseService();

  // Dashboard verileri
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double totalDebt = 0.0;

  // İşlemler listesi
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  Future<void> _reloadData() async {
    // 1) Dashboard verileri
    final totals = await _dbService.calculateTotals();
    setState(() {
      totalIncome = totals["income"] ?? 0.0;
      totalExpense = totals["expense"] ?? 0.0;
      totalDebt = totals["debt"] ?? 0.0;
    });

    // 2) İşlemler listesi
    final txList = await _dbService.fetchAllTransactions();
    setState(() {
      transactions = txList.map((tx) {
        final dt = DateTime.parse(tx["date"]);
        return {...tx, "date": dt}; // "date" string -> DateTime
      }).toList();
    });
  }

  Future<void> _deleteTransaction(Map<String, dynamic> item) async {
    await _dbService.deleteTransaction(item);
    await _reloadData();
  }

  PreferredSizeWidget _buildEmptyAppBar() {
    return AppBar(
      title: const Text(""),
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 10,
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildMenuButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Kullanıcı bulunamadı.")),
      );
    }

    final availableBalance = totalIncome - totalExpense - totalDebt;

    return Scaffold(
      appBar: _buildEmptyAppBar(),
      body: Column(
        children: [
          // D A S H B O A R D
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DashboardBox(
                  title: "Gelir",
                  value: totalIncome,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IncomePage()),
                  ),
                ),
                DashboardBox(
                  title: "Gider",
                  value: totalExpense,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpensePage()),
                  ),
                ),
                DashboardBox(
                  title: "Borç",
                  value: totalDebt,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DebtPage()),
                  ),
                ),
                DashboardBox(
                  title: "Kullanılabilir",
                  value: availableBalance,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AvailableBalancePage()),
                  ),
                ),
                DashboardBox(
                  title: "Toplam",
                  value: availableBalance,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TotalPage()),
                  ),
                ),
              ],
            ),
          ),

          // İŞLEMLER LİSTESİ
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text("Henüz işlem yok."))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      final dateStr = DateFormat("dd MMM yyyy, HH:mm")
                          .format(item["date"]);
                      final color =
                          item["amount"] < 0 ? Colors.red : Colors.green;
                      final amountStr =
                          item["amount"].toStringAsFixed(2);
                      final note = item["note"] ?? "";

                      return Dismissible(
                        key: Key("${item["docKey"]}_${item["type"]}"),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          setState(() {
                            transactions.removeAt(index);
                          });
                          await _deleteTransaction(item);
                        },
                        child: ListTile(
                          title: Text(
                            item["title"] ?? "",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "$dateStr - ${item["type"]}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Text(
                            "$amountStr ₺",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          onTap: () {
                            if (item["type"] == "Gider") {
                              final positiveAmount =
                                  item["amount"] < 0 ? -item["amount"] : item["amount"];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditExpensePage(
                                    docKey: item["docKey"],
                                    title: item["title"] ?? "",
                                    note: note,
                                    amount: positiveAmount,
                                    date: item["date"],
                                  ),
                                ),
                              ).then((_) => _reloadData());
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Bu kayıt türü şimdilik düzenlenemiyor."),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),

          // ALT MENÜ
          Container(
            height: 100,
            color: Colors.blueGrey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMenuButton(label: "Ana Sayfa", onTap: () {}),
                _buildMenuButton(label: "Öneriler", onTap: () {}),
                _buildMenuButton(label: "Hesap Kitap", onTap: () {}),
                _buildMenuButton(label: "Ayarlar", onTap: () {}),
                _buildMenuButton(label: "Profil", onTap: () {}),
              ],
            ),
          ),
        ],
      ),

      // + BUTONU
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNewExpense()),
          );
          await _reloadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
