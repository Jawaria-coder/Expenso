import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class TransferScreen extends StatefulWidget {
  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final Color kPrimaryColor = const Color(0xFF9B59B6);

  late DateTime selectedDate;
  late String formattedDate;

  final TextEditingController amountController = TextEditingController();

  final List<String> fromWallets = ['Cash', 'Credit Card', 'Debit Card', 'Bank Account'];
  String? selectedFromWallet;

  final List<String> toWallets = ['Cash', 'Credit Card', 'Debit Card', 'Bank Account'];
  String? selectedToWallet;

  String selectedCurrency = '';
  String selectedType = 'Transfer';

  BannerAd? _bannerAd;
  bool isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    formattedDate = DateFormat('dd/MM/yyyy (EEE)').format(selectedDate);
    selectedFromWallet = fromWallets[0];
    selectedToWallet = toWallets[1];
    loadSelectedCurrency();
    loadBannerAd();
  }

  void loadSelectedCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currency = prefs.getString('selectedCurrency');

    if (currency != null) {
      setState(() {
        selectedCurrency = currency;
      });
    } else {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc['currency'] != null) {
          setState(() {
            selectedCurrency = userDoc['currency'];
          });
          prefs.setString('selectedCurrency', userDoc['currency']);
        }
      }
    }
  }

  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // 🔁 Replace with your own ID
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => isBannerAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad failed: $error');
        },
      ),
    )..load();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        formattedDate = DateFormat('dd/MM/yyyy (EEE)').format(selectedDate);
      });
    }
  }

  Future<void> saveTransfer() async {
    if (selectedFromWallet == null || selectedToWallet == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (selectedFromWallet == selectedToWallet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From and To wallets cannot be the same')),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('transfers').add({
        'userId': user.uid,
        'fromWallet': selectedFromWallet,
        'toWallet': selectedToWallet,
        'amount': amount,
        'date': Timestamp.fromDate(selectedDate),
        'currency': selectedCurrency,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer saved!')),
      );

      setState(() {
        amountController.clear();
        selectedFromWallet = fromWallets[0];
        selectedToWallet = toWallets[1];
        selectedDate = DateTime.now();
        formattedDate = DateFormat('dd/MM/yyyy (EEE)').format(selectedDate);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save transfer: $e')),
      );
    }
  }

  Widget buildNumPad(Color textColor) {
    final keyboardHeight = MediaQuery.of(context).size.height * 0.4;

    return Container(
      height: keyboardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          String text;
          VoidCallback? onTap;

          if (index < 9) {
            text = '${index + 1}';
            onTap = () {
              amountController.text += text;
              setState(() {});
            };
          } else if (index == 9) {
            text = '.';
            onTap = () {
              if (!amountController.text.contains('.')) {
                amountController.text += text;
                setState(() {});
              }
            };
          } else if (index == 10) {
            text = '0';
            onTap = () {
              amountController.text += text;
              setState(() {});
            };
          } else {
            text = '⌫';
            onTap = () {
              if (amountController.text.isNotEmpty) {
                amountController.text =
                    amountController.text.substring(0, amountController.text.length - 1);
                setState(() {});
              }
            };
          }

          return OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kPrimaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onTap,
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          );
        },
      ),
    );
  }

  Widget buildDropdown(String label, List<String> items, String? selectedItem,
      ValueChanged<String?> onChanged, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kPrimaryColor),
          ),
          child: DropdownButton<String>(
            value: selectedItem,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            iconEnabledColor: kPrimaryColor,
            dropdownColor: isDark ? Colors.grey[900] : Colors.white,
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: kPrimaryColor),
                    const SizedBox(width: 8),
                    Text(value, style: GoogleFonts.poppins(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : kPrimaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Transfer',
          style: TextStyle(
            color: isDark ? Colors.white : kPrimaryColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : kPrimaryColor,
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: saveTransfer,
        child: const Icon(Icons.check, color: Colors.white),
        backgroundColor: kPrimaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Transfer funds between your wallets securely and easily!',
                            style: GoogleFonts.poppins(fontSize: 13),
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
                              color: isSelected ? kPrimaryColor : background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kPrimaryColor),
                            ),
                            child: Center(
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : kPrimaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text("Date", style: GoogleFonts.poppins(fontSize: 13)),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.calendar_today, color: kPrimaryColor),
                        onPressed: () => _selectDate(context),
                      ),
                      Text(formattedDate,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildDropdown('From', fromWallets, selectedFromWallet, (val) {
                    setState(() => selectedFromWallet = val);
                  }, Icons.account_balance_wallet_outlined),
                  const SizedBox(height: 16),
                  buildDropdown('To', toWallets, selectedToWallet, (val) {
                    setState(() => selectedToWallet = val);
                  }, Icons.wallet),
                  const SizedBox(height: 16),
                  Text("Amount", style: GoogleFonts.poppins(fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kPrimaryColor),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(' $selectedCurrency', style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          amountController.text.isEmpty ? "0" : amountController.text,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildNumPad(textColor),
                ],
              ),
            ),
          ),
          if (isBannerAdLoaded)
            Container(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
