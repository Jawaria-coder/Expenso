import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'accountDetailsPage.dart';
import 'CurrencySelectionScreen.dart';
import 'main.dart';
import 'termsPage.dart';
import 'privacyPolicyPage.dart';
import 'aboutUsPage.dart';
import 'supportPage.dart';
import 'feedbackPage.dart';
import 'faqPage.dart';

class AccountPage extends StatelessWidget {
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color lightPurple = const Color(0xFF9C27B0);

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text('Signed out')),
      );
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text('Error signing out')),
      );
    }
  }

  final List<_OptionItem> options = const [
    _OptionItem('Account', Icons.person_outline),
    _OptionItem('Currency', Icons.attach_money_outlined),
    _OptionItem('FAQs', Icons.question_answer_outlined),
    _OptionItem('Terms of Use', Icons.description_outlined),
    _OptionItem('Privacy Policy', Icons.lock_outline),
    _OptionItem('About Us', Icons.info_outline),
    _OptionItem('Help & Support', Icons.support_agent_outlined),
    _OptionItem('Feedback', Icons.feedback_outlined),
    _OptionItem('Sign Out', Icons.logout_outlined),
  ];

  void _handleTap(BuildContext context, String title) {
    switch (title) {
      case 'Account':
        Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailsPage()));
        break;
      case 'Currency':
        _showCurrencyDialog(context);
        break;
      case 'Terms of Use':
        Navigator.push(context, MaterialPageRoute(builder: (_) => TermsPage()));
        break;
      case 'Privacy Policy':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyPage()));
        break;
      case 'About Us':
        Navigator.push(context, MaterialPageRoute(builder: (_) => AboutUsPage()));
        break;
      case 'Help & Support':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SupportPage()));
        break;
      case 'Feedback':
        Navigator.push(context, MaterialPageRoute(builder: (_) => FeedbackPage()));
        break;
      case 'FAQs':
        Navigator.push(context, MaterialPageRoute(builder: (_) => FAQPage()));
        break;
      case 'Sign Out':
        signOut(); // ✅ Fixed
        break;
    }
  }

  Widget _buildOptionTile(BuildContext context, _OptionItem option) {
    return InkWell(
      onTap: () => _handleTap(context, option.title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(option.icon, size: 24, color: primaryPurple),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option.title,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) async {
    List<String> currencies = [
      'USD', 'EUR', 'GBP', 'JPY', 'AUD',
      'CAD', 'CHF', 'CNY', 'SEK', 'NZD', 'PKR'
    ];
    String? selectedCurrency;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      selectedCurrency = doc.data()?['currency'];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Currency'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 250, // ✅ Limit the height for scrollability
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: currencies.map((currency) {
                      return RadioListTile<String>(
                        title: Text(currency),
                        value: currency,
                        groupValue: selectedCurrency,
                        onChanged: (value) {
                          setState(() {
                            selectedCurrency = value;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: selectedCurrency == null
                  ? null
                  : () async {
                await _saveCurrencyToFirestore(selectedCurrency!);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _saveCurrencyToFirestore(String currency) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'currency': currency,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text('Currency updated to $currency')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: primaryPurple),
      ),
      body: ListView.builder(
        itemCount: options.length,
        itemBuilder: (context, index) => _buildOptionTile(context, options[index]),
      ),
    );
  }
}

class _OptionItem {
  final String title;
  final IconData icon;
  const _OptionItem(this.title,this.icon);
}