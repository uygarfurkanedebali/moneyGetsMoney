// lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import 'income_page.dart';
import 'expense_page.dart';
import 'debt_page.dart';
import 'available_balance_page.dart';
import 'total_page.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Ana Sayfa'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _buildToolbarButton(context, 'Gelir', IncomePage()),
                _buildToolbarButton(context, 'Gider', ExpensePage()),
                _buildToolbarButton(context, 'Borç', DebtPage()),
                _buildToolbarButton(context, 'Kullanılabilir Bakiye', AvailableBalancePage()),
                _buildToolbarButton(context, 'Toplam', TotalPage()),
              ],
            ),
          ),
          // Ana içerik alanı – buraya ek bir özet bilgi ya da rehber metin ekleyebilirsiniz.
          Expanded(
            child: Center(
              child: Text('Lütfen üstteki araç çubuğundan bir sayfa seçin.'),
            ),
          ),
        ],
      ),
    );
  }
}
