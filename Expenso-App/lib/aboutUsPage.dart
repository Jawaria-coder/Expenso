import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryPurple = Color(0xFF6A1B9A); // example purple color

class AboutUsPage extends StatelessWidget {
  final String aboutText = '''
About Us

Welcome to Expense Manager!

At Expense Manager, our mission is to simplify the way you handle your daily finances. We believe that budgeting and tracking expenses should be easy, intuitive, and accessible to everyone.

What We Offer:
- A user-friendly interface to log and review your expenses.
- Budget planning tools to help you manage your monthly goals.
- Insights to help you make smarter financial decisions.

Why Choose Us?
We prioritize your privacy. Your data stays on your device unless you choose to back it up securely. No ads. No clutter. Just effective money management.

Our Vision:
To empower individuals with tools that make financial well-being a daily habit.

Thank you for choosing Expense Manager. We're here to support you on your financial journey!
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Us',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : primaryPurple),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            aboutText,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: isDark ? Colors.white : Colors.purple[900],
            ),
          ),
        ),
      ),
    );
  }
}
