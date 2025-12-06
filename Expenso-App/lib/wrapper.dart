// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'LoadingScreen.dart';
// import 'Verify.dart';
// import 'LoginPage.dart';
// import 'CurrencySelectionScreen.dart';
// import 'HomePage.dart';
//
// class Wrapper extends StatefulWidget {
//   @override
//   State<Wrapper> createState() => _WrapperState();
// }
//
// class _WrapperState extends State<Wrapper> {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return LoadingScreen();
//         }
//
//         if (snapshot.hasData) {
//           final user = snapshot.data!;
//
//           if (!user.emailVerified) {
//             return Verify();
//           }
//
//           return FutureBuilder<DocumentSnapshot>(
//             future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
//             builder: (context, userSnapshot) {
//               if (userSnapshot.connectionState == ConnectionState.waiting) {
//                 return LoadingScreen();
//               }
//
//               if (userSnapshot.hasData && userSnapshot.data!.exists) {
//                 final userData = userSnapshot.data!.data() as Map<String, dynamic>;
//
//                 if (userData['currency'] == null) {
//                   return CurrencySelectionScreen();
//                 } else {
//                   return HomePage();
//                 }
//               } else {
//                 return LoginPage();
//               }
//             },
//           );
//         }
//
//         return LoginPage();
//       },
//     );
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/AddMoneyScreen.dart';
import 'package:project/home_loader.dart';
import 'LoadingScreen.dart';
import 'Verify.dart';
import 'LoginPage.dart';
import 'CurrencySelectionScreen.dart';
import 'HomePage.dart';

class Wrapper extends StatefulWidget {
  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;

          if (!user.emailVerified) {
            return Verify();
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return LoadingScreen();
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;

                // New logic
                if (userData['currency'] == null) {
                  return CurrencySelectionScreen();
                } else if (userData['isFirstTime'] == true) {
                  return AddMoneyScreen();
                } else {
                  return HomePage();
                }
              } else {
                return LoginPage();
              }
            },
          );
        }

        return LoginPage();
      },
    );
  }
}
