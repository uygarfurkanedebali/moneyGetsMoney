// lib/screens/available_balance_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AvailableBalancePage extends StatefulWidget {
  const AvailableBalancePage({Key? key}) : super(key: key);

  @override
  State<AvailableBalancePage> createState() => _AvailableBalancePageState();
}

class _AvailableBalancePageState extends State<AvailableBalancePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double totalDebt = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateBalance();
  }

  Future<void> _calculateBalance() async {
    User? user = _auth.currentUser;
    if (user == null) return;
    // Gelirler
    DataSnapshot incomeSnapshot =
        await _database.child('users/${user.uid}/incomes').get();
    if (incomeSnapshot.exists) {
      Map incomes = incomeSnapshot.value as Map;
      incomes.forEach((key, value) {
        totalIncome += (value['amount'] as num).toDouble();
      });
    }
    // Giderler
    DataSnapshot expenseSnapshot =
        await _database.child('users/${user.uid}/expenses').get();
    if (expenseSnapshot.exists) {
      Map expenses = expenseSnapshot.value as Map;
      expenses.forEach((key, value) {
        totalExpense += (value['amount'] as num).toDouble();
      });
    }
    // Borçlar
    DataSnapshot debtSnapshot =
        await _database.child('users/${user.uid}/debts').get();
    if (debtSnapshot.exists) {
      Map debts = debtSnapshot.value as Map;
      debts.forEach((key, value) {
        totalDebt += (value['amount'] as num).toDouble();
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double availableBalance = totalIncome - totalExpense - totalDebt;
    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanılabilir Bakiye'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Toplam Gelir: $totalIncome',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Toplam Gider: $totalExpense',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Toplam Borç: $totalDebt', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            Text('Kullanılabilir Bakiye: $availableBalance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
