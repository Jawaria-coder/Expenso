import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:google_fonts/google_fonts.dart';

class CafeCalculator extends StatefulWidget {
  @override
  _CafeCalculatorState createState() => _CafeCalculatorState();
}

class _CafeCalculatorState extends State<CafeCalculator> {
  String _input = '';

  void _buttonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _input = '';
      } else if (value == '=') {
        try {
          _input = _calculate(_input).toString();
          if (_input.endsWith('.0')) {
            _input = _input.substring(0, _input.length - 2);
          }
        } catch (e) {
          _input = 'Error';
        }
      } else {
        if (_input.isNotEmpty &&
            '+-×÷'.contains(value) &&
            '+-×÷'.contains(_input[_input.length - 1])) {
          _input = _input.substring(0, _input.length - 1) + value;
        } else {
          _input += value;
        }
      }
    });
  }

  double _calculate(String expr) {
    Parser p = Parser();
    String parsedExpr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    Expression exp = p.parse(parsedExpr);
    ContextModel cm = ContextModel();
    return exp.evaluate(EvaluationType.REAL, cm);
  }

  Widget _buildButton(String value, {Color? color, required bool isDarkMode}) {
    bool isNumber = RegExp(r'^\d$').hasMatch(value);

    return InkWell(
      onTap: () => _buttonPressed(value),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode && isNumber
              ? Colors.white // solid white for numbers in dark mode
              : (color?.withOpacity(0.3) ??
              (isDarkMode
                  ? Color(0xFF1E1E1E)
                  : Colors.white70.withOpacity(0.3))),
          border: Border.all(
            color: isDarkMode ? Color(0xFF9C27B0) : Colors.brown.shade800,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: isDarkMode && isNumber
                  ? Colors.black // dark mode mein white background ke liye black text
                  : (isDarkMode
                  ? Color(0xFFE1BEE7)
                  : Colors.brown.shade900),
            ),
          ),
        ),
      ),
    );
  }


  Color _getButtonColor(String btn, bool isDarkMode) {
    if (btn == 'C') return Colors.purple;
    if (btn == '=') return Colors.purpleAccent;
    if ('×÷-+'.contains(btn)) return Colors.purple;
    if (isDarkMode && RegExp(r'^\d$').hasMatch(btn)) return Colors.white; // ✔ white for numbers in dark mode
    return isDarkMode ? Colors.white : Colors.white;
  }


  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = isDarkMode
        ? LinearGradient(
      colors: [Color(0xFF121212), Color(0xFF1A1A1A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : LinearGradient(
      colors: [Colors.white, Colors.white],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Calculator',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Color(0xFF9B59B6),
          ),
        ),
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Color(0xFF9B59B6),
        ),
      ),

      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                alignment: Alignment.bottomRight,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
                  border: Border.all(
                    color: isDarkMode ? Color(0xFF9C27B0) : Colors.brown.shade800,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _input,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Color(0xFFFFFDE7) : Colors.brown.shade900,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.2,
                  children: [
                    ...['7', '8', '9', '÷'],
                    ...['4', '5', '6', '×'],
                    ...['1', '2', '3', '-'],
                    ...['C', '0', '=', '+'],
                  ]
                      .map((btn) => _buildButton(
                    btn,
                    color: _getButtonColor(btn, isDarkMode),
                    isDarkMode: isDarkMode,
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}