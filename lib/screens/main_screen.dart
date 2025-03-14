// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:money_gets_money/screens/add_new_expanse.dart';
import 'income_page.dart';
import 'expense_page.dart';
import 'debt_page.dart';
import 'available_balance_page.dart';
import 'total_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  late Future<Map?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map?> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final DataSnapshot snapshot =
          await _database.child("users/${user.uid}").get();
      if (snapshot.exists) {
        return snapshot.value as Map?;
      }
    }
    return null;
  }

  Widget _buildToolbarButton(BuildContext context, String label, Widget page) {
    return Expanded(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Ana Sayfa')),
        body: Center(child: Text("Kullanıcı bulunamadı")),
      );
    }
    
    // Kullanıcının giderlerini dinlemek için reference
    DatabaseReference expensesRef =
        _database.child("users/${user.uid}/expenses");

    return Scaffold(
      appBar: AppBar(
        title: Text('Ana Sayfa'),
      ),
      body: FutureBuilder<Map?>(
        future: _userDataFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError) {
            return Center(child: Text("Hata: ${userSnapshot.error}"));
          }
          Map? userData = userSnapshot.data;
          return Column(
            children: [
              // Dashboard araç çubuğu
              Container(
                color: Colors.grey[200],
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _buildToolbarButton(context, 'Gelir', IncomePage()),
                    _buildToolbarButton(context, 'Gider', ExpensePage()),
                    _buildToolbarButton(context, 'Borç', DebtPage()),
                    _buildToolbarButton(context, 'Kullanılabilir', AvailableBalancePage()),
                    _buildToolbarButton(context, 'Toplam', TotalPage()),
                  ],
                ),
              ),
              // Kullanıcı bilgileri ve gider listesi
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Hoşgeldiniz, ${user.email}",
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Kayıt zamanı: ${userData?['createdAt'] ?? 'Bilinmiyor'}",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: expensesRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Hata: ${snapshot.error}"));
                    }
                    if (snapshot.data?.snapshot.value == null) {
                      return Center(child: Text("Hiç harcama bulunamadı."));
                    }
                    Map expensesMap =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    List expenseKeys = expensesMap.keys.toList();
                    return ListView.builder(
                      itemCount: expenseKeys.length,
                      itemBuilder: (context, index) {
                        String key = expenseKeys[index].toString();
                        Map expense = expensesMap[key];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(expense['title'] ?? "Başlık Yok"),
                            subtitle: Text(
                                "Tutar: ${expense['amount']?.toString() ?? "0"}\nTarih: ${expense['date'] ?? ''}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await expensesRef.child(key).remove();
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddNewExpense()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
