// lib/screens/debt_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:money_gets_money/screens/add_new_debt.dart';

class DebtPage extends StatefulWidget {
  const DebtPage({Key? key}) : super(key: key);

  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
          appBar: AppBar(title: Text('Borç')),
          body: Center(child: Text('Kullanıcı bulunamadı')));
    }
    DatabaseReference debtsRef =
        _database.child('users/${user.uid}/debts');
    DatabaseReference debtCategoriesRef =
        _database.child('users/${user.uid}/debtCategories');

    return Scaffold(
      appBar: AppBar(
        title: Text('Borç'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddNewDebtPage()));
            },
          ),
          IconButton(
            icon: Icon(Icons.category),
            onPressed: () async {
              // Yeni kategori eklemek için dialog
              String? newCategory = await showDialog<String>(
                context: context,
                builder: (context) {
                  TextEditingController _catController =
                      TextEditingController();
                  return AlertDialog(
                    title: Text('Yeni Borç Kategorisi Ekle'),
                    content: TextField(
                      controller: _catController,
                      decoration: InputDecoration(hintText: 'Kategori adı'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, _catController.text.trim());
                        },
                        child: Text('Ekle'),
                      ),
                    ],
                  );
                },
              );
              if (newCategory != null && newCategory.isNotEmpty) {
                await debtCategoriesRef.push().set(newCategory);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Kategori filtreleme için dropdown
          StreamBuilder<DatabaseEvent>(
            stream: debtCategoriesRef.onValue,
            builder: (context, snapshot) {
              List<String> categories = [];
              if (snapshot.hasData &&
                  snapshot.data!.snapshot.value != null) {
                Map data = snapshot.data!.snapshot.value as Map;
                data.forEach((key, value) {
                  categories.add(value.toString());
                });
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  hint: Text('Kategori Seçin'),
                  value: _selectedCategory,
                  items: categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  },
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: debtsRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
                  return Center(child: Text('Hiç borç kaydı yok.'));
                Map debtsMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List debtKeys = debtsMap.keys.toList();

                // Seçili kategori varsa filtreleme
                if (_selectedCategory != null) {
                  debtKeys = debtKeys.where((key) {
                    Map debt = debtsMap[key];
                    return debt['category'] == _selectedCategory;
                  }).toList();
                }

                return ListView.builder(
                  itemCount: debtKeys.length,
                  itemBuilder: (context, index) {
                    String key = debtKeys[index].toString();
                    Map debt = debtsMap[key];
                    return ListTile(
                      title:
                          Text(debt['description'] ?? 'Borç'),
                      subtitle: Text(
                          'Tutar: ${debt['amount']} - Kategori: ${debt['category']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await debtsRef.child(key).remove();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddNewDebtPage extends StatefulWidget {
  const AddNewDebtPage({Key? key}) : super(key: key);

  @override
  State<AddNewDebtPage> createState() => _AddNewDebtPageState();
}

class _AddNewDebtPageState extends State<AddNewDebtPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  bool _isSaving = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
    });
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("Kullanıcı bulunamadı");
      DatabaseReference debtsRef =
          _database.child('users/${user.uid}/debts');
      String debtKey = debtsRef.push().key!;
      Map<String, dynamic> debtData = {
        'description': _descController.text.trim(),
        'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
        'category': _categoryController.text.trim(),
        'date': DateTime.now().toIso8601String(),
      };
      await debtsRef.child(debtKey).set(debtData);
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
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Borç Ekle'),
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
                      decoration:
                          InputDecoration(labelText: 'Borç Açıklaması'),
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
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(labelText: 'Kategori'),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Kategori gerekli';
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _saveDebt, child: Text('Kaydet')),
                  ],
                ),
              ),
      ),
    );
  }
}
