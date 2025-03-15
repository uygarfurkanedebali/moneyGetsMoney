import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class EditExpensePage extends StatefulWidget {
  final String docKey; // Firebase'deki unique key
  final String title;
  final double amount;
  final String note;
  final DateTime date;

  const EditExpensePage({
    Key? key,
    required this.docKey,
    required this.title,
    required this.amount,
    required this.note,
    required this.date,
  }) : super(key: key);

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  DateTime? _selectedDate;
  final _dateFormat = DateFormat("dd MMM yyyy");

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _amountController = TextEditingController(text: widget.amount.toString());
    _noteController = TextEditingController(text: widget.note);
    _selectedDate = widget.date;
  }

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Kullanıcı oturumu bulunamadı.");
      }
      final uid = user.uid;

      // Tarih yoksa (garanti olsun diye) bugünün tarihini kullanıyoruz.
      final DateTime savingDate = _selectedDate ?? DateTime.now();

      // Güncellenecek harcama verisi
      Map<String, dynamic> updatedData = {
        'title': _titleController.text.trim(),
        'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
        'note': _noteController.text.trim(),
        'date': savingDate.toIso8601String(),
      };

      // Firebase'e güncelleme
      DatabaseReference expenseRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(uid)
          .child("expenses")
          .child(widget.docKey);

      await expenseRef.update(updatedData);

      // Kayıt tamamlanınca geri dön
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Harcama güncellenirken hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme hatası: $e")),
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
    String dateText = _selectedDate == null
        ? "Tarih Seçilmedi"
        : _dateFormat.format(_selectedDate!);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Harcamayı Düzenle"),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration:
                          const InputDecoration(labelText: "Harcama Başlığı"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Bu alan boş olamaz.";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Tutar (TL)"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Lütfen tutar girin";
                        }
                        if (double.tryParse(value) == null) {
                          return "Geçerli bir sayı girin";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: "Not"),
                    ),
                    const SizedBox(height: 20),
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
                      onPressed: _saveChanges,
                      child: const Text("Kaydet"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
