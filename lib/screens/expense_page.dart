// lib/screens/expense_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_new_expanse_page.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({Key? key}) : super(key: key);

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
          appBar: AppBar(title: Text('Gider')),
          body: Center(child: Text('Kullanıcı bulunamadı')));
    }
    DatabaseReference expensesRef =
        _database.child('users/${user.uid}/expenses');

    return Scaffold(
      appBar: AppBar(
        title: Text('Gider'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddNewExpense()));
            },
          )
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: expensesRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('Hiç gider kaydı yok.'));
          }
          Map expensesMap = snapshot.data!.snapshot.value as Map;
          List expenseKeys = expensesMap.keys.toList();
          return ListView.builder(
            itemCount: expenseKeys.length,
            itemBuilder: (context, index) {
              String key = expenseKeys[index].toString();
              Map expense = expensesMap[key];
              return ListTile(
                title: Text(expense['title'] ?? 'Harcama'),
                subtitle: Text(
                    'Tutar: ${expense['amount']} - Tarih: ${expense['date']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await expensesRef.child(key).remove();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
