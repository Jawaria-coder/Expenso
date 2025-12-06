import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> with TickerProviderStateMixin {
  String selectedType = 'Expense';
  String? selectedCategory;
  String selectedAccount = 'Bank';

  final TextEditingController categoryController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  final List<List<dynamic>> categories = [
    ['Food', Icons.fastfood],
    ['Transport', Icons.directions_car],
    ['Shopping', Icons.shopping_cart],
    ['Bills', Icons.receipt],
    ['Entertainment', Icons.movie],
    ['Other', Icons.more_horiz],
  ];

  final List<Map<String, dynamic>> customCategories = [];

  final List<String> accountOptions = ['Bank', 'Cash', 'Credit', 'Debit'];

  late DateTime selectedDate;
  late String formattedDate;

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    formattedDate = DateFormat('dd/MM/yyyy (EEE)').format(selectedDate);
    accountController.text = selectedAccount;

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Ad failed to load: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        formattedDate = DateFormat('dd/MM/yyyy (EEE)').format(selectedDate);
      });
    }
  }

  Future<void> _saveExpense() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage("User not logged in");
      return;
    }

    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (selectedCategory == null) {
      _showMessage("Please select a category");
      return;
    }
    if (amount <= 0) {
      _showMessage("Please enter a valid amount");
      return;
    }

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists || !userSnapshot.data()!.containsKey('wallet')) {
        _showMessage("Wallet not found or invalid data");
        return;
      }

      // 🔥 Fix here: convert wallet to double regardless of it being int or double
      double currentBalance = (userSnapshot.data()!['wallet'] as num).toDouble();
      double newBalance = currentBalance - amount;

      if (newBalance < 0) {
        _showMessage("Insufficient balance");
        return;
      }

      await FirebaseFirestore.instance.collection('expenses').add({
        'userId': user.uid,
        'type': selectedType,
        'category': selectedCategory,
        'amount': amount,
        'account': selectedAccount,
        'note': noteController.text.trim(),
        'date': selectedDate,
        'createdAt': Timestamp.now(),
      });

      await userDoc.update({'wallet': newBalance});

      _showMessage("Expense added and wallet updated!");

      setState(() {
        selectedCategory = null;
        categoryController.clear();
        amountController.clear();
        noteController.clear();
      });
    } catch (e) {
      _showMessage("Failed to save expense: $e");
    }
  }


  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: GoogleFonts.poppins())),
    );
  }

  Future<void> _showCustomCategoryDialog() async {
    String customCategory = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Custom Category', style: GoogleFonts.poppins()),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g., Medicine',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              customCategory = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                if (customCategory.trim().isNotEmpty) {
                  setState(() {
                    customCategories.add({
                      'name': customCategory.trim(),
                      'icon': Icons.more_horiz,
                    });
                    selectedCategory = customCategory.trim();
                    categoryController.text = customCategory.trim();
                  });
                }
                Navigator.pop(context);
              },
              child: Text('Done', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final primaryColor = const Color(0xFF9B59B6);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Expense',
          style: TextStyle(
            color: isDark ? Colors.white : primaryColor,
          ),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveExpense,
        child: const Icon(Icons.check, color: Colors.white),
        backgroundColor: primaryColor,
        mini: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Income', 'Expense', 'Transfer'].map((type) {
                      final isSelected = selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => selectedType = type);
                            Navigator.pushReplacementNamed(context, '/${type.toLowerCase()}');
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryColor, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text("Date", style: GoogleFonts.poppins(color: textColor, fontSize: 13)),
                      IconButton(
                        icon: Icon(Icons.calendar_today, color: primaryColor),
                        onPressed: () => _selectDate(context),
                      ),
                      Text(formattedDate, style: GoogleFonts.poppins(color: textColor)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: buildTextField("Amount", amountController, primaryColor)),
                      const SizedBox(width: 10),
                      Expanded(child: buildTextField("Category", categoryController, primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: buildDropdownField("Account", primaryColor)),
                      const SizedBox(width: 10),
                      Expanded(child: buildTextField("Note", noteController, primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text("Select Category", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3 / 2,
                      children: [
                        ...categories.map((category) {
                          final isSelected = selectedCategory == category[0];
                          return GestureDetector(
                            onTap: () async {
                              if (category[0] == 'Other') {
                                await _showCustomCategoryDialog();
                              } else {
                                setState(() {
                                  selectedCategory = category[0];
                                  categoryController.text = category[0];
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor.withOpacity(0.1) : bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? primaryColor : primaryColor.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(category[1] as IconData, color: primaryColor),
                                        const SizedBox(height: 4),
                                        Text(category[0],
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(fontSize: 12, color: textColor)),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Icon(Icons.check_circle, color: primaryColor, size: 18),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                        ...customCategories.map((category) {
                          final isSelected = selectedCategory == category['name'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = category['name'];
                                categoryController.text = category['name'];
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor.withOpacity(0.1) : bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? primaryColor : primaryColor.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(category['icon'], color: primaryColor),
                                        const SizedBox(height: 4),
                                        Text(category['name'],
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(fontSize: 12, color: textColor)),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Icon(Icons.check_circle, color: primaryColor, size: 18),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isBannerAdReady)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, Color primaryColor) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: theme.textTheme.bodyLarge?.color)),
        SizedBox(
          height: 35,
          child: TextField(
            controller: controller,
            style: GoogleFonts.poppins(color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDropdownField(String label, Color primaryColor) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: theme.textTheme.bodyLarge?.color)),
        SizedBox(
          height: 35,
          child: DropdownButtonFormField<String>(
            value: selectedAccount,
            items: accountOptions.map((String account) {
              return DropdownMenuItem<String>(
                value: account,
                child: Text(account, style: GoogleFonts.poppins()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedAccount = value!;
                accountController.text = value;
              });
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
