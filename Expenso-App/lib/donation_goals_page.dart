import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/ThemeProvider.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _donations = [];
  String _userCurrency = "\$";
  double _walletBalance = 0;

  static const purplyPink = Color(0xFF9B59B6);
  static const purplyBlue = Color(0xFF9A9FDC);
  static const darkPurple = Color(0xFF481463);

  @override
  void initState() {
    super.initState();
    _loadDonations();
    _loadUserCurrency();
    _loadWalletBalance();
  }

  Future<void> _loadUserCurrency() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data()?['currency'] != null) {
      setState(() {
        _userCurrency = userDoc.data()!['currency'];
      });
    }
  }

  Future<void> _loadWalletBalance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data()?['wallet'] != null) {
      setState(() {
        _walletBalance = (userDoc.data()!['wallet'] as num).toDouble();
      });
    }
  }

  Future<void> _updateWalletBalance(double amountChange) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDocRef);
      if (!snapshot.exists) return;
      double currentWallet = (snapshot['wallet'] as num).toDouble();
      double newWallet = currentWallet + amountChange;
      transaction.update(userDocRef, {'wallet': newWallet});
      _walletBalance = newWallet;
    });
    setState(() {}); // Update UI
  }

  Future<void> _loadDonations() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      _donations = snapshot.docs
          .map((doc) => {
        'id': doc.id,
        'name': doc['name'],
        'amount': doc['amount'],
        'timestamp': doc['timestamp'],
      })
          .toList();
    });
  }

  Future<void> _makeDonation({String? name, double? amount}) async {
    final donationName = name ?? _nameController.text.trim();
    final donationAmount = amount ?? double.tryParse(_amountController.text.trim()) ?? 0;

    if (donationName.isEmpty || donationAmount <= 0) return;

    if (donationAmount > _walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Not enough money in wallet")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('donations').add({
        'userId': uid,
        'name': donationName,
        'amount': donationAmount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _updateWalletBalance(-donationAmount);

      _nameController.clear();
      _amountController.clear();

      await _loadDonations();
    } catch (e) {
      // Handle error gracefully
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDonation(String donationId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('donations').doc(donationId).delete();
      await _loadDonations();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAllDonations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await _loadDonations();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editDonationDialog(Map<String, dynamic> donation) async {
    final nameController = TextEditingController(text: donation['name']);
    final amountController = TextEditingController(text: donation['amount'].toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Donation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: amountController, decoration: InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final updatedName = nameController.text.trim();
              final updatedAmount = double.tryParse(amountController.text.trim()) ?? 0;

              if (updatedName.isEmpty || updatedAmount <= 0) return;

              await FirebaseFirestore.instance.collection('donations').doc(donation['id']).update({
                'name': updatedName,
                'amount': updatedAmount,
              });

              Navigator.pop(context);
              await _loadDonations();
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final bgColor = isDarkMode ? Colors.black : Colors.white;
    final appBarColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : darkPurple;
    final cardColor = isDarkMode ? Colors.black : Colors.white;
    final buttonBgColor = purplyPink;
    final borderColor = isDarkMode ? Colors.purple[300]! : purplyBlue;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text("Make a Donation", style: TextStyle(color: purplyPink)),
        iconTheme: IconThemeData(color: purplyPink),
        elevation: 1,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("New Donation", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: purplyPink)),
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Donation For (Name)',
                      labelStyle: TextStyle(color: textColor),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: buttonBgColor, width: 2)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      labelStyle: TextStyle(color: textColor),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: buttonBgColor, width: 2)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter an amount';
                      final val = double.tryParse(value.trim());
                      if (val == null || val <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) _makeDonation();
                    },
                    child: Text("Donate"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBgColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            if (_donations.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Donation History", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                  IconButton(icon: Icon(Icons.delete_forever, color: Colors.red), onPressed: _deleteAllDonations),
                ],
              ),
            SizedBox(height: 16),
            ..._donations.map((donation) {
              final amount = (donation['amount'] as num).toDouble();
              final name = donation['name'];
              final timestamp = donation['timestamp'] as Timestamp?;
              final timeStr = timestamp != null ? _formatDateTime(timestamp.toDate()) : "Unknown";
              final donationId = donation['id'];

              return Card(
                color: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Donated $_userCurrency ${amount.toStringAsFixed(2)} to $name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                      SizedBox(height: 4),
                      Text("Date: $timeStr", style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _editDonationDialog(donation),
                            icon: Icon(Icons.edit, color: Colors.orange),
                            label: Text("Edit", style: TextStyle(color: Colors.orange)),
                          ),
                          TextButton.icon(
                            onPressed: () => _makeDonation(name: name, amount: amount),
                            icon: Icon(Icons.replay, color: Colors.green),
                            label: Text("Donate Again", style: TextStyle(color: Colors.green)),
                          ),
                          TextButton.icon(
                            onPressed: () => _deleteDonation(donationId),
                            icon: Icon(Icons.delete, color: Colors.red),
                            label: Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
