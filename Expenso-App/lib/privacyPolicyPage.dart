import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryPurple = Color(0xFF6A1B9A); // example purple color

class PrivacyPolicyPage extends StatelessWidget {
  final String privacyText = '''

Privacy Policy

Welcome to Expense Manager!

Your privacy is important to us. This privacy policy explains how we collect, use, and protect your personal information.

1. Data Collection  
We collect only the data necessary to provide you with our services. This includes expense records and budget information you input into the app.

2. Data Storage  
Your data is stored locally on your device by default. If you enable cloud sync, data will be stored securely on our cloud servers.

3. Data Usage  
We use your data solely to help you manage your expenses and budgets effectively. We do not sell or share your data with third parties.

4. Security Measures  
We implement reasonable security measures to protect your data from unauthorized access or disclosure.

5. User Control  
You have full control over your data. You can edit or delete your records at any time.

6. Changes to this Policy  
We may update this policy occasionally. We will notify you of any significant changes.

Thank you for trusting Expense Manager!

If you have any questions, please contact us at support@expensemanager.com.
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
            privacyText,
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
