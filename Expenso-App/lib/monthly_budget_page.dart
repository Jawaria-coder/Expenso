import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'BudgetOverview.dart';

const primaryColor = Color(0xFF9B59B6);

class MonthlyBudgetPage extends StatefulWidget {
  @override
  _MonthlyBudgetPage createState() => _MonthlyBudgetPage();
}

class _MonthlyBudgetPage extends State<MonthlyBudgetPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _selectedCategory;
  List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
    'Others'
  ];

  DateTime? _startDate;
  DateTime? _endDate;

  List<BudgetExtended> _allBudgets = [];

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = prefs.getStringList('budgetList') ?? [];
    final budgets = jsonList
        .map((jsonStr) => BudgetExtended.fromJson(json.decode(jsonStr)))
        .toList();
    setState(() => _allBudgets = budgets);
  }

  Future<void> _saveBudget(BudgetExtended budget) async {
    final prefs = await SharedPreferences.getInstance();
    _allBudgets.add(budget);
    final jsonList = _allBudgets.map((b) => json.encode(b.toJson())).toList();
    await prefs.setStringList('budgetList', jsonList);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('User not logged in');
      return;
    }
    final userId = user.uid;

    final firestore = FirebaseFirestore.instance;

    await firestore.collection('users').doc(userId).collection('budgets').add({
      'category': budget.category,
      'budgetAmount': budget.budgetAmount,
      'spentAmount': budget.spentAmount,
      'amountLeft': budget.amountLeft,
      'startDate': budget.startDate.toIso8601String(),
      'endDate': budget.endDate.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _showMessage('Budget saved successfully in Firestore');
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        _showMessage('Please select both start and end dates');
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        _showMessage('End date cannot be before start date');
        return;
      }

      final category = _selectedCategory ?? _categoryController.text.trim();
      if (category.isEmpty) {
        _showMessage('Please enter or select a category');
        return;
      }

      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        _showMessage('Please enter a valid positive amount');
        return;
      }

      final budget = BudgetExtended(
        category: category,
        budgetAmount: amount,
        spentAmount: 0,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      await _saveBudget(budget);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget saved successfully!')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BudgetOverviewScreen()),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.grey[800]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          )
              : ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _showAddCustomCategoryDialog() async {
    TextEditingController customCategoryController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: AlertDialog(
            title: Text('Add Custom Category'),
            content: TextField(
              controller: customCategoryController,
              decoration: InputDecoration(hintText: 'Enter category name'),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final newCategory = customCategoryController.text.trim();
                  if (newCategory.isNotEmpty && !_categories.contains(newCategory)) {
                    setState(() {
                      _categories.insert(_categories.length - 1, newCategory);
                      _selectedCategory = newCategory;
                      _categoryController.text = newCategory;
                    });
                  }
                  Navigator.pop(context);
                },
                child: Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) =>
      date == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(date);

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Color(0xFF121212) : Color(0xFFF9F9FB);
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : primaryColor),
        title: Text(
          'Add Budget',
          style: TextStyle(
            color: isDark ? Colors.white : primaryColor,
          ),
        ),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              Icons.account_balance_wallet_outlined,
              color: isDark ? Colors.white : Color(0xFF9B59B6),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/budgetPage'); // 🔁 replace with your actual route
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildAmountFieldStyled(textColor, cardColor),
              SizedBox(height: 16),
              _buildDateFieldStyled('Start Date', _startDate, true, textColor, cardColor),
              SizedBox(height: 16),
              _buildDateFieldStyled('End Date', _endDate, false, textColor, cardColor),
              SizedBox(height: 24),
              Text("Select Category",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              _buildCategoryGrid(isDark),
              SizedBox(height: 30),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    "Submit Budget",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountFieldStyled(Color textColor, Color fillColor) {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount',
        labelStyle: TextStyle(color: textColor),
        prefixIcon: Icon(Icons.attach_money, color: primaryColor, size: 20),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      style: TextStyle(color: textColor),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter an amount';
        final n = num.tryParse(value);
        if (n == null || n <= 0) return 'Enter a valid positive number';
        return null;
      },
    );
  }

  Widget _buildDateFieldStyled(String label, DateTime? date, bool isStart, Color textColor, Color fillColor) {
    return InkWell(
      onTap: () => _pickDate(isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDate(date), style: TextStyle(color: textColor)),
            Icon(Icons.calendar_today, size: 20, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    final icons = {
      'Food': Icons.restaurant,
      'Transport': Icons.directions_car,
      'Entertainment': Icons.movie,
      'Shopping': Icons.shopping_cart,
      'Bills': Icons.receipt,
      'Others': Icons.category,
    };

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _categories.map((category) {
        final isSelected = category == _selectedCategory;
        return GestureDetector(
          onTap: () {
            if (category == 'Others') {
              _showAddCustomCategoryDialog();
            } else {
              setState(() {
                _selectedCategory = category;
                _categoryController.text = category;
              });
            }
          },
          child: Container(
            width: 100,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? primaryColor : (isDark ? Color(0xFF1E1E1E) : Colors.white),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black54 : Colors.grey.shade300,
                  blurRadius: 6,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icons[category] ?? Icons.category,
                  size: 36,
                  color: isSelected ? Colors.white : primaryColor.withOpacity(0.7),
                ),
                SizedBox(height: 8),
                Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

  double get amountLeft => budgetAmount - spentAmount;

  Map<String, dynamic> toJson() => {
    'category': category,
    'budgetAmount': budgetAmount,
    'spentAmount': spentAmount,
    'amountLeft': amountLeft,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
  };

  factory BudgetExtended.fromJson(Map<String, dynamic> json) => BudgetExtended(
    category: json['category'],
    budgetAmount: (json['budgetAmount'] as num).toDouble(),
    spentAmount: (json['spentAmount'] as num).toDouble(),
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
  );
}