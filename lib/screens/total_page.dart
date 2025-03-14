// lib/screens/total_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class TotalPage extends StatefulWidget {
  const TotalPage({Key? key}) : super(key: key);

  @override
  State<TotalPage> createState() => _TotalPageState();
}

class _TotalPageState extends State<TotalPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double totalDebt = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotals();
  }

  Future<void> _calculateTotals() async {
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
        title: Text('Toplam Bakiye'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text('Toplam Gelir'),
              trailing: Text(totalIncome.toStringAsFixed(2)),
            ),
            ListTile(
              title: Text('Toplam Gider'),
              trailing: Text(totalExpense.toStringAsFixed(2)),
            ),
            ListTile(
              title: Text('Toplam Borç'),
              trailing: Text(totalDebt.toStringAsFixed(2)),
            ),
            Divider(),
            ListTile(
              title: Text('Kullanılabilir Bakiye',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(availableBalance.toStringAsFixed(2),
                  style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
