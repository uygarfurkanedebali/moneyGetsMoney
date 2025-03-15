// lib/services/database_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Toplamları hesaplar (Gelir, Gider, Borç)
  Future<Map<String, double>> calculateTotals() async {
    User? user = _auth.currentUser;
    if (user == null) {
      return {"income": 0.0, "expense": 0.0, "debt": 0.0};
    }

    double tempIncome = 0.0;
    double tempExpense = 0.0;
    double tempDebt = 0.0;

    // Gelir
    final incSnap = await _db.child('users/${user.uid}/incomes').get();
    if (incSnap.exists) {
      final incMap = incSnap.value as Map;
      incMap.forEach((key, value) {
        tempIncome += (value['amount'] as num).toDouble();
      });
    }

    // Gider
    final expSnap = await _db.child('users/${user.uid}/expenses').get();
    if (expSnap.exists) {
      final expMap = expSnap.value as Map;
      expMap.forEach((key, value) {
        tempExpense += (value['amount'] as num).toDouble();
      });
    }

    // Borç
    final debtSnap = await _db.child('users/${user.uid}/debts').get();
    if (debtSnap.exists) {
      final debtMap = debtSnap.value as Map;
      debtMap.forEach((key, value) {
        tempDebt += (value['amount'] as num).toDouble();
      });
    }

    return {
      "income": tempIncome,
      "expense": tempExpense,
      "debt": tempDebt,
    };
  }

  // Tüm işlemleri çek (Gelir, Gider, Borç) => tek listede birleştir, tarihine göre sırala
  Future<List<Map<String, dynamic>>> fetchAllTransactions() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    List<Map<String, dynamic>> tempList = [];

    // Gelir
    final incSnap = await _db.child('users/${user.uid}/incomes').get();
    if (incSnap.exists) {
      final incMap = incSnap.value as Map;
      incMap.forEach((key, value) {
        tempList.add({
          "docKey": key,
          "title": value["description"] ?? "Gelir",
          "note": "",
          "amount": (value["amount"] as num).toDouble(),
          "date": value["date"],
          "type": "Gelir",
        });
      });
    }

    // Gider
    final expSnap = await _db.child('users/${user.uid}/expenses').get();
    if (expSnap.exists) {
      final expMap = expSnap.value as Map;
      expMap.forEach((key, value) {
        tempList.add({
          "docKey": key,
          "title": value["title"] ?? "Gider",
          "note": value["note"] ?? "",
          "amount": -(value["amount"] as num).toDouble(),
          "date": value["date"],
          "type": "Gider",
        });
      });
    }

    // Borç
    final debtSnap = await _db.child('users/${user.uid}/debts').get();
    if (debtSnap.exists) {
      final debtMap = debtSnap.value as Map;
      debtMap.forEach((key, value) {
        tempList.add({
          "docKey": key,
          "title": value["description"] ?? "Borç",
          "note": "",
          "amount": -(value["amount"] as num).toDouble(),
          "date": value["date"],
          "type": "Borç",
        });
      });
    }

    // Tarihine göre (en yeni üstte) sıralama
    tempList.sort((a, b) {
      final dateA = DateTime.parse(a["date"]);
      final dateB = DateTime.parse(b["date"]);
      return dateB.compareTo(dateA);
    });

    return tempList;
  }

  // Tek bir kaydı silme
  Future<void> deleteTransaction(Map<String, dynamic> item) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final docKey = item["docKey"];
    final type = item["type"];

    if (type == "Gelir") {
      await _db.child('users/${user.uid}/incomes/$docKey').remove();
    } else if (type == "Gider") {
      await _db.child('users/${user.uid}/expenses/$docKey').remove();
    } else if (type == "Borç") {
      await _db.child('users/${user.uid}/debts/$docKey').remove();
    }
  }
}
