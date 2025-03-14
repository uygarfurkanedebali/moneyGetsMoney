// lib/screens/income_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({Key? key}) : super(key: key);

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
          appBar: AppBar(title: Text('Gelir')),
          body: Center(child: Text('Kullanıcı bulunamadı')));
    }
    DatabaseReference incomesRef = _database.child('users/${user.uid}/incomes');

    return Scaffold(
      appBar: AppBar(
        title: Text('Gelir'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddNewIncomePage()));
            },
          )
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: incomesRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('Hiç gelir kaydı yok.'));
          }
          Map incomesMap = snapshot.data!.snapshot.value as Map;
          List incomeKeys = incomesMap.keys.toList();
          return ListView.builder(
            itemCount: incomeKeys.length,
            itemBuilder: (context, index) {
              String key = incomeKeys[index].toString();
              Map income = incomesMap[key];
              return ListTile(
                title: Text(income['description'] ?? 'Gelir'),
                subtitle: Text(
                    'Tutar: ${income['amount']} - Tarih: ${income['date']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await incomesRef.child(key).remove();
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

class AddNewIncomePage extends StatefulWidget {
  const AddNewIncomePage({Key? key}) : super(key: key);

  @override
  State<AddNewIncomePage> createState() => _AddNewIncomePageState();
}

class _AddNewIncomePageState extends State<AddNewIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isSaving = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
    });
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("Kullanıcı bulunamadı");
      DatabaseReference incomesRef =
          _database.child('users/${user.uid}/incomes');
      String incomeKey = incomesRef.push().key!;
      Map<String, dynamic> incomeData = {
        'description': _descController.text.trim(),
        'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
        'date': DateTime.now().toIso8601String(),
      };
      await incomesRef.child(incomeKey).set(incomeData);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Gelir Ekle'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal Et', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSaving
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(labelText: 'Gelir Açıklaması'),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Açıklama gerekli';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(labelText: 'Tutar'),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Tutar gerekli';
                        if (double.tryParse(value) == null)
                          return 'Geçerli bir sayı girin';
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(onPressed: _saveIncome, child: Text('Kaydet')),
                  ],
                ),
              ),
      ),
    );
  }
}
