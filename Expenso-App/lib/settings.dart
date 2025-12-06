import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project/services/notification_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account.dart';
import 'main.dart';

void main() {
  runApp(const SettingsApp());
}

class SettingsApp extends StatefulWidget {
  const SettingsApp({Key? key}) : super(key: key);

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModeSetting();
  }

  Future<void> _loadDarkModeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeEnabled = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() {
      _darkModeEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: SettingsPage(
        darkModeEnabled: _darkModeEnabled,
        onDarkModeChanged: _toggleDarkMode,
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final bool darkModeEnabled;
  final ValueChanged<bool> onDarkModeChanged;

  const SettingsPage({
    Key? key,
    required this.darkModeEnabled,
    required this.onDarkModeChanged,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);

    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      await NotificationService.instance.showImmediateNotification(
        id: 0,
        title: "Wallet App",
        body: "You have subscribed to the Notifications, You will see notifications From us Now!",
      );

      await NotificationService.instance.scheduleNotification(
        id: 1,
        title: "Scheduled Notification",
        body: "This notification is scheduled after toggle ON!",
        hour: 21,
        minute: 45,
      );
    }
  }

  void _onRecommend() {
    const String message = '''
✨ Manage your money like a pro!  
I’m using this smart Expense Tracker app – and it’s a game changer!  
💼 Track. 💡 Save. 💰 Grow.  
Download now 👉 https://yourappwebsite.com
''';
    Share.share(message);
  }

  Future<void> _confirmAndDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: const Text(
          'Are you sure you want to delete your account and all associated data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteUserDataAndAccount();
    }
  }

  // Future<void> _deleteUserDataAndAccount() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('No user is currently signed in')),
  //     );
  //     return;
  //   }
  //
  //   final uid = user.uid;
  //   final firestore = FirebaseFirestore.instance;
  //
  //   try {
  //     // Delete subcollections
  //     await _deleteSubcollection(firestore.collection('users').doc(uid), 'budgets');
  //     await _deleteSubcollection(firestore.collection('users').doc(uid), 'income');
  //
  //     // Delete main user doc
  //     await firestore.collection('users').doc(uid).delete();
  //
  //     // Delete other user-related docs
  //     await _deleteUserDocsInCollection('expenses', uid);
  //     await _deleteUserDocsInCollection('donations', uid);
  //     await _deleteUserDocsInCollection('feedbacks', uid);
  //     await _deleteUserDocsInCollection('notes', uid);
  //     await _deleteUserDocsInCollection('transfers', uid);
  //
  //     // ✅ Reauthenticate with Google before delete
  //     final GoogleSignIn googleSignIn = GoogleSignIn();
  //     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  //
  //     if (googleUser == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Sign-in canceled')),
  //       );
  //       return;
  //     }
  //
  //     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     await user.reauthenticateWithCredential(credential);
  //     await user.delete();
  //
  //     // ✅ Sign out + clear cache
  //     await FirebaseAuth.instance.signOut();
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.clear();
  //
  //     // ✅ Navigate only after everything is cleaned up
  //     if (!mounted) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Account deleted and cache cleared')),
  //     );
  //
  //     // 🟢 Go back to login screen
  //     navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  //
  //
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to delete account: $e')),
  //     );
  //   }
  // }

  Future<void> _deleteUserDataAndAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in')),
      );
      return;
    }

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      // Delete subcollections
      await _deleteSubcollection(firestore.collection('users').doc(uid), 'budgets');
      await _deleteSubcollection(firestore.collection('users').doc(uid), 'income');

      // Delete main user doc
      await firestore.collection('users').doc(uid).delete();

      // Delete other user-related docs
      await _deleteUserDocsInCollection('expenses', uid);
      await _deleteUserDocsInCollection('donations', uid);
      await _deleteUserDocsInCollection('feedbacks', uid);
      await _deleteUserDocsInCollection('notes', uid);
      await _deleteUserDocsInCollection('transfers', uid);

      // 🔍 Determine sign-in method
      String provider = user.providerData.isNotEmpty
          ? user.providerData[0].providerId
          : '';

      // 🔐 Reauthenticate
      if (provider == 'google.com') {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google sign-in canceled')),
          );
          return;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await user.reauthenticateWithCredential(credential);
      } else if (provider == 'password') {
        // Ask user for their password
        String? password = await _showPasswordDialog();
        if (password == null) return;

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);
      } else {
        throw Exception("Unsupported provider: $provider");
      }

      // 🔥 Delete the account
      await user.delete();

      // ✅ Sign out and clear cache
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted and cache cleared')),
      );

      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }


  Future<String?> _showPasswordDialog() async {
    TextEditingController _passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Re-enter your password"),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _passwordController.text),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }



  Future<void> _deleteSubcollection(DocumentReference docRef, String subcollectionName) async {
    final subcollectionRef = docRef.collection(subcollectionName);
    final snapshots = await subcollectionRef.get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _deleteUserDocsInCollection(String collectionName, String uid) async {
    final collectionRef = FirebaseFirestore.instance.collection(collectionName);

    while (true) {
      final snapshot = await collectionRef.where('userId', isEqualTo: uid).limit(100).get();
      if (snapshot.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteAllData() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text('Are you sure you want to delete all your data? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final firestore = FirebaseFirestore.instance;

    try {
      Future<void> deleteDocsInCollection(String collectionName, String field) async {
        final snapshot = await firestore.collection(collectionName).where(field, isEqualTo: uid).get();

        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }

      await deleteDocsInCollection('expenses', 'userId');
      await deleteDocsInCollection('donations', 'userId');
      await deleteDocsInCollection('feedbacks', 'userId');
      await deleteDocsInCollection('notes', 'userId');
      await deleteDocsInCollection('transfers', 'userId');

      Future<void> deleteSubcollectionDocs(String subcollectionName) async {
        final subSnapshot = await firestore.collection('users').doc(uid).collection(subcollectionName).get();

        for (final doc in subSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      await deleteSubcollectionDocs('budgets');
      await deleteSubcollectionDocs('income');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All user data deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete data: $e')),
      );
    }
  }

  void _onAccountSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AccountPage()),
    );
  }

  Widget _buildSettingOption({
    required Widget leading,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 15),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Color(0xFF9B59B6),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Color(0xFF9B59B6),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            SwitchListTile(
              title: const Text('Notifications'),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              secondary: const Icon(Icons.notifications),
            ),
            _buildSettingOption(
              leading: const Icon(Icons.person),
              title: 'Account Settings',
              onTap: _onAccountSettings,
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            ),
            _buildSettingOption(
              leading: const Icon(Icons.recommend),
              title: 'Recommend to Friends',
              onTap: _onRecommend,
              trailing: const Icon(Icons.share),
            ),
            _buildSettingOption(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: 'Delete Account',
              onTap: _confirmAndDeleteAccount,
              trailing: const Icon(Icons.delete_forever, color: Colors.red),
            ),
            _buildSettingOption(
              leading: const Icon(Icons.delete, color: Colors.orange),
              title: 'Delete All Data',
              onTap: _deleteAllData,
              trailing: const Icon(Icons.delete, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}
