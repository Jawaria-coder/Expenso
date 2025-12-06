import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

const Color primaryPurple = Color(0xFF6A1B9A);

class SupportPage extends StatelessWidget {
  const SupportPage({Key? key}) : super(key: key);

  void _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@expensemanager.com',
      queryParameters: {'subject': 'Support Request'},
    );

    try {
      if (!await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
        _showError(context, 'No email app is available to handle this request.');
      }
    } catch (e) {
      _showError(context, 'Failed to launch email: ${e.toString()}');
    }
  }


  void _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+12345678900');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showError(context, 'Could not open the phone dialer.');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconBackgroundColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.grey[900] : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: primaryPurple.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? primaryPurple.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, size: 28, color: primaryPurple),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              trailing ??
                  Icon(Icons.arrow_forward_ios,
                      size: 20,
                      color: isDark
                          ? Colors.white70
                          : Colors.deepPurple.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = primaryPurple;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          'Support',
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.08),
                  accentColor.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              'Need help or have questions? Reach out to our support team anytime via email or phone. We’re here to help you get the best experience!',
              style: GoogleFonts.poppins(
                fontSize: 17,
                height: 1.5,
                color: isDark ? Colors.white70 : accentColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildOption(
            context: context,
            icon: Icons.email_outlined,
            title: 'Email Support',
            onTap: () => _launchEmail(context),
            iconBackgroundColor: accentColor.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          _buildOption(
            context: context,
            icon: Icons.phone_outlined,
            title: 'Call Support',
            onTap: () => _launchPhone(context),
            iconBackgroundColor: accentColor.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}