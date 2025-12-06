import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class IncomeScreen extends StatefulWidget {
  @override
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> with TickerProviderStateMixin {
  String selectedType = 'Income';
  String? selectedCategory;
  String selectedAccount = 'Bank';

  final TextEditingController categoryController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  final List<List<dynamic>> categories = [
    ['Salary', Icons.attach_money],
    ['Freelance', Icons.computer],
    ['Investment', Icons.trending_up],
    ['Business', Icons.business_center],
    ['Gift', Icons.card_giftcard],
    ['Other', Icons.more_horiz],
  ];

  final List<String> accountOptions = ['Bank', 'Cash', 'Credit', 'Debit'];

  late DateTime selectedDate;
  late String formattedDate;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    formattedDate = DateFormat('dd/MM/yyyy (EEE)').format(selectedDate);

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad failed to load: $error');
        },
      ),
    )..load();
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

  Future<void> _saveIncome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage("User not logged in");
      return;
    }

    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (selectedCategory == null || selectedCategory!.isEmpty) {
      _showMessage("Please select a category");
      return;
    }
    if (amount == null || amount <= 0) {
      _showMessage("Please enter a valid amount");
      return;
    }

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      final walletData = userSnapshot.data()?['wallet'];
      if (walletData == null) {
        _showMessage("Wallet not found or invalid data");
        return;
      }

      double currentBalance = (walletData as num).toDouble();
      double newBalance = currentBalance + amount;

      await userDoc.collection('income').add({
        'type': selectedType,
        'category': selectedCategory,
        'amount': amount,
        'account': selectedAccount,
        'note': noteController.text.trim(),
        'date': selectedDate,
        'createdAt': Timestamp.now(),
      });

      await userDoc.update({'wallet': newBalance});

      _showMessage("✅ Income added and wallet updated!");

      setState(() {
        selectedCategory = null;
        categoryController.clear();
        amountController.clear();
        noteController.clear();
      });
    } catch (e) {
      _showMessage("❌ Failed to save income: $e");
    }
  }

  void _showCustomCategoryDialog() {
    final TextEditingController customController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enter Custom Category", style: GoogleFonts.poppins()),
        content: TextField(
          controller: customController,
          decoration: InputDecoration(
            hintText: "e.g. Side Hustle",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              final input = customController.text.trim();
              if (input.isNotEmpty) {
                setState(() {
                  selectedCategory = input;
                  categoryController.text = input;
                });
              }
              Navigator.pop(context);
            },
            child: Text("Add", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
      ),
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
          'Add Income',
          style: TextStyle(
            color: isDark ? Colors.white : primaryColor,
          ),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveIncome,
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
                  /// ✅ BANNER SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Make sure your category and amount are correct before saving!",
                            style: GoogleFonts.poppins(color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      Expanded(
                        child: IgnorePointer(
                          child: buildTextField("Category", categoryController, primaryColor),
                        ),
                      ),
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
                      children: categories.map((category) {
                        final isOther = category[0] == 'Other';
                        final isSelected = selectedCategory == category[0];

                        return GestureDetector(
                          onTap: () {
                            if (isOther) {
                              _showCustomCategoryDialog();
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
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_bannerAd != null)
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
