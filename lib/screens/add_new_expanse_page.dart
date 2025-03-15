// lib/screens/add_new_expense.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için

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

  // Tarih seçimi için değişken
  DateTime? _selectedDate;

  // Tarihi güzel göstermek için formatter
  final _dateFormat = DateFormat("dd MMM yyyy");

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

      // Kullanıcı tarih seçmemişse bugünün tarihini kullan
      DateTime savingDate = _selectedDate ?? DateTime.now();

      DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .child('expenses');

      // Yeni harcama kaydı için unique bir key
      String expenseKey = ref.push().key!;
      Map<String, dynamic> expenseData = {
        'title': _titleController.text.trim(),
        'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
        'note': _noteController.text.trim(),
        'date': savingDate.toIso8601String(),
      };
      await ref.child(expenseKey).set(expenseData);

      Navigator.pop(context); // Kaydedildikten sonra önceki sayfaya dön.
    } catch (e) {
      debugPrint("Harcama kaydedilirken hata: $e");
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

  // Tarih seçmek için fonksiyon
  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    // showDatePicker ile kullanıcıya takvim gösterilir
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
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
    String dateText = _selectedDate == null
        ? "Tarih Seçilmedi"
        : _dateFormat.format(_selectedDate!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Harcama Ekle'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal Et',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  // ListView => büyük ekranlarda kaydırma
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration:
                          const InputDecoration(labelText: 'Harcama Başlığı'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen harcama başlığı girin';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _amountController,
                      decoration:
                          const InputDecoration(labelText: 'Tutar (TL)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                      decoration: const InputDecoration(labelText: 'Not'),
                    ),
                    const SizedBox(height: 20),
                    // Tarih seçme butonu
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Tarih: $dateText",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        TextButton(
                          onPressed: _pickDate,
                          child: const Text("Tarih Seç"),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveExpense,
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
