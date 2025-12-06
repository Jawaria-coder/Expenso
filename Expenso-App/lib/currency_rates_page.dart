import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class CurrencyRatesPage extends StatefulWidget {
  @override
  _CurrencyRatesPageState createState() => _CurrencyRatesPageState();
}

class _CurrencyRatesPageState extends State<CurrencyRatesPage> {
  late Future<Map<String, dynamic>> _futureRates;

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  void _fetchRates() {
    setState(() {
      _futureRates = fetchCurrencyRates();
    });
  }

  Future<Map<String, dynamic>> fetchCurrencyRates() async {
    final apiKey = 'de47a4c5e89e13e63c7830d8';
    final url = 'https://v6.exchangerate-api.com/v6/$apiKey/latest/USD';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] == 'success') {
        return data['conversion_rates'];
      } else {
        throw Exception('Failed to fetch currency rates');
      }
    } else {
      throw Exception('Failed to fetch currency rates');
    }
  }

  final List<String> currenciesToShow = [
    'EUR',
    'GBP',
    'INR',
    'AUD',
    'CAD',
    'JPY',
    'CNY',
    'CHF',
    'NZD',
    'ZAR',
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFF9B59B6);
    final Color accentColor = primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Currency Exchange Rates',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : primaryColor,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? Colors.white : accentColor,
            ),
            tooltip: 'Refresh Rates',
            onPressed: _fetchRates,
          ),
        ],
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : primaryColor,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureRates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Error loading rates:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Text(
                'No data available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            );
          } else {
            final rates = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: currenciesToShow.length,
              itemBuilder: (context, index) {
                final currency = currenciesToShow[index];
                final rate = rates[currency];

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (!isDarkMode)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: primaryColor.withOpacity(0.15),
                      child: Text(
                        currency,
                        style: GoogleFonts.poppins(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      'USD → $currency',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : primaryColor,
                      ),
                    ),
                    trailing: Text(
                      rate.toStringAsFixed(4),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: accentColor,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}