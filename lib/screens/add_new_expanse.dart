// lib/screens/add_new_expense.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddNewExpense extends StatefulWidget {
  const AddNewExpense({Key? key}) : super(key: key);

  @override
  _AddNewExpenseState createState() => _AddNewExpenseState();
}

class _AddNewExpenseState extends State<AddNewExpense> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
    });
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Kullanıcı oturumu bulunamadı.");
      }
      String uid = user.uid;
      // Firebase Realtime Database'de kullanıcının expenses listesine ekleme yapıyoruz.
      DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .child('expenses');

      // Yeni harcama kaydı için unique bir key oluşturuyoruz.
      String expenseKey = ref.push().key!;
      Map<String, dynamic> expenseData = {
        'title': _titleController.text.trim(),
        'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
        'note': _noteController.text.trim(),
        'date': DateTime.now().toIso8601String(),
      };
      await ref.child(expenseKey).set(expenseData);
      Navigator.pop(context); // Kaydedildikten sonra önceki sayfaya dön.
    } catch (e) {
      print("Harcama kaydedilirken hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt sırasında hata oluştu: $e")),
      );
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
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Harcama Ekle'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal Et',
              style: TextStyle(color: Colors.white),
            ),
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
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Harcama Başlığı'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen harcama başlığı girin';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(labelText: 'Tutar'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen tutarı girin';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Lütfen geçerli bir sayı girin';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(labelText: 'Not (isteğe bağlı)'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveExpense,
                      child: Text('Kaydet'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
