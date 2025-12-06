// LoadingScreen.dart
import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECE9F7),
      body: Stack(
        children: [
          // Background Circles
          Positioned(
            top: -60,
            left: -30,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.pinkAccent.withOpacity(0.2),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -30,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.purpleAccent.withOpacity(0.2),
            ),
          ),

          // Loader and Text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.purpleAccent),
                SizedBox(height: 20),
                Text(
                  "Checking authentication...",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
