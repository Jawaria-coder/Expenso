import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const primaryColor = Color(0xFF9C27B0);
const cardLightColor = Color(0xFFF5F5F5);
const cardDarkColor = Color(0xFF1E1E1E);
const backgroundLight = Color(0xFFE0E0E0);
const backgroundDark = Color(0xFF121212);

// RouteObserver remains the same
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class BudgetOverviewScreen extends StatefulWidget {
  @override
  State<BudgetOverviewScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetOverviewScreen> with RouteAware {
  List<BudgetExtended> _budgets = [];
  bool _isLoading = true;
  String _currencySymbol = '₹';

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _fetchBudgets();
  }

  DateTime parseDate(dynamic dateField) {
    if (dateField is Timestamp) return dateField.toDate();
    if (dateField is DateTime) return dateField;
    if (dateField is String) return DateTime.parse(dateField);
    throw Exception('Unsupported date format');
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _fetchBudgets() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _budgets = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      _currencySymbol = userDoc.data()?['currency'] ?? '₹';

      final budgetSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .get();

      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      final allExpenses = expenseSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'category': data['category'] ?? '',
          'amount': (data['amount'] ?? 0).toDouble(),
          'date': parseDate(data['date']),
        };
      }).toList();

      List<BudgetExtended> loadedBudgets = [];

      for (var doc in budgetSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? '';
        final budgetAmount = (data['budgetAmount'] ?? 0).toDouble();
        final startDate = parseDate(data['startDate']);
        final endDate = parseDate(data['endDate']);

        double spent = 0.0;

        for (var expense in allExpenses) {
          final expenseDate = expense['date'] as DateTime;
          final expenseCategory = expense['category'];
          final expenseAmount = expense['amount'] as double;

          if (expenseCategory == category &&
              !expenseDate.isBefore(startDate) &&
              !expenseDate.isAfter(endDate)) {
            spent += expenseAmount;
          }
        }

        loadedBudgets.add(BudgetExtended(
          category: category,
          budgetAmount: budgetAmount,
          spentAmount: spent,
          startDate: startDate,
          endDate: endDate,
        ));
      }

      setState(() {
        _budgets = loadedBudgets;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching budgets and expenses: $e");
      setState(() => _isLoading = false);
    }
  }

  Widget _buildBudgetCard(BudgetExtended budget, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? cardDarkColor : cardLightColor;
    final textColor = isDark ? Colors.white : Colors.black;

    double amountLeft = budget.budgetAmount - budget.spentAmount;
    String leftText = amountLeft >= 0
        ? 'Left: $_currencySymbol ${amountLeft.toStringAsFixed(2)}'
        : 'Overspent: $_currencySymbol ${amountLeft.abs().toStringAsFixed(2)}';

    double spentPercent = budget.budgetAmount == 0
        ? 0
        : (budget.spentAmount / budget.budgetAmount).clamp(0.0, 1.0);

    Color progressColor = spentPercent < 0.7
        ? Colors.green
        : (spentPercent < 1 ? Colors.orange : Colors.red);

    return Card(
      color: cardColor,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              budget.category,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'From ${_formatDate(budget.startDate)} to ${_formatDate(budget.endDate)}',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget: $_currencySymbol ${budget.budgetAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                ),
                Text(
                  'Spent: $_currencySymbol ${NumberFormat('#,##0.00').format(budget.spentAmount)}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                ),
                Text(
                  leftText,
                  style: TextStyle(
                    color: amountLeft >= 0 ? textColor : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: spentPercent,
                minHeight: 14,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? backgroundDark : backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Color(0xFF9B59B6),
        ),
        title: Text(
          'Add Budget',
          style: TextStyle(
            color: isDark ? Colors.white : Color(0xFF9B59B6),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 1,
      ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
          ? Center(child: Text('No budgets found.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black)))
          : ListView.builder(
        itemCount: _budgets.length,
        itemBuilder: (context, index) {
          return _buildBudgetCard(_budgets[index], index);
        },
      ),
    );
  }
}

class BudgetExtended {
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final DateTime startDate;
  final DateTime endDate;

  BudgetExtended({
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.startDate,
    required this.endDate,
  });
}