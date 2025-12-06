import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryPurple = Color(0xFF6A1B9A); // example purple color

class TermsPage extends StatelessWidget {
  final String termsText = '''
Welcome to Expense Manager!

Please read the terms and conditions carefully before using this app:

1. Purpose: Expense Manager is designed to help you track your daily expenses and manage your budget effectively.

2. Data Privacy: We do not collect or store your personal financial data on external servers. All data is saved locally on your device unless cloud sync is enabled.

3. User Responsibility: You are responsible for the accuracy of the data you input. We are not liable for any financial losses resulting from the use of this application.

4. Updates: The app may be updated from time to time. We will notify users about significant changes in terms or features.

5. Limitations: While we strive to offer accurate and reliable services, Expense Manager is provided "as is" without warranties of any kind.

By using this app, you agree to these terms.

Thank you for trusting Expense Manager!
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : primaryPurple,
        ),
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
            termsText,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Theme.of(context).textTheme.bodyMedium?.color,

            ),
          ),
        ),
      ),
    );
  }
}