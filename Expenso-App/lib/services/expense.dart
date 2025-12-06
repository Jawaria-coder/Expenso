import 'package:cloud_firestore/cloud_firestore.dart';

class expense {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addExpense({
    required String amount,
    required String category,
    required String account,
    required String note,
    required String currency,
    required DateTime date,
  }) async {
    await _firestore.collection('expenses').add({
      'amount': amount,
      'category': category,
      'account': account,
      'note': note,
      'currency': currency,
      'date': date.toIso8601String(),
    });
  }

  Future<void> addIncome({
    required String amount,
    required String category,
    required String account,
    required String note,
    required String currency,
    required DateTime date,
  }) async {
    await _firestore.collection('incomes').add({
      'amount': amount,
      'category': category,
      'account': account,
      'note': note,
      'currency': currency,
      'date': date.toIso8601String(),
    });
  }

  Future<void> addTransfer({
    required String fromAccount,
    required String toAccount,
    required String amount,
    required String currency,
    required DateTime date,
  }) async {
    await _firestore.collection('transfers').add({
      'from': fromAccount,
      'to': toAccount,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
    });
  }
}
