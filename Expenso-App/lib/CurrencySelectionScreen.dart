import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'AddMoneyScreen.dart';

class CurrencySelectionScreen extends StatefulWidget {
  @override
  _CurrencySelectionScreenState createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  final List<String> currencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY', 'SEK', 'NZD', 'PKR'
  ];
  String? selectedCurrency;

  final Color primaryPurple = const Color(0xFF9B59B6);

  @override
  void initState() {
    super.initState();
    loadCurrency();
  }

  void loadCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currency = prefs.getString('selectedCurrency');
    if (currency != null) {
      setState(() {
        selectedCurrency = currency;
      });
    }
  }

  // void saveCurrency(String currency) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('selectedCurrency', currency);
  //
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
  //       'currency': currency,
  //     });
  //   }
  //
  //   Navigator.pushReplacementNamed(context, '/home');
  // }

  void saveCurrency(String currency) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCurrency', currency);

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'currency': currency,
      });
    }

    // Navigate to add money screen instead of home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AddMoneyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2BFD9),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            left: -30,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: primaryPurple.withOpacity(0.3),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -30,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: primaryPurple.withOpacity(0.3),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose Currency',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 250,
                    child: DropdownButtonFormField<String>(
                      value: selectedCurrency,
                      hint: const Text('Select Currency'),
                      items: currencies.map((currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCurrency = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelStyle: TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: selectedCurrency == null
                          ? null
                          : () => saveCurrency(selectedCurrency!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        "Continue",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
