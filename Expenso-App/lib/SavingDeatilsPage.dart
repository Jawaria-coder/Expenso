import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavingDetailsPage extends StatelessWidget {
  final String userId;

  const SavingDetailsPage({super.key, required this.userId});

  Future<String> getUserCurrency() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return userDoc.data()?['currency'] ?? 'PKR';
  }

  Future<void> editSavingDialog(BuildContext context, String docId, String name, double amount, String date) async {
    final nameController = TextEditingController(text: name);
    final amountController = TextEditingController(text: amount.toString());
    final dateController = TextEditingController(text: date);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Saving"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: amountController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Amount")),
            TextField(controller: dateController, decoration: InputDecoration(labelText: "Date")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newAmount = double.tryParse(amountController.text.trim()) ?? 0;
              final newDate = dateController.text.trim();

              if (newName.isEmpty || newAmount <= 0 || newDate.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('savings')
                  .doc(docId)
                  .update({
                'name': newName,
                'amount': newAmount,
                'date': newDate,
              });

              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteSaving(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savings')
        .doc(docId)
        .delete();
  }

  Future<void> deleteAllSavings(BuildContext context) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savings')
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All savings deleted")));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final iconColor = theme.colorScheme.primary;

    return FutureBuilder<String>(
      future: getUserCurrency(),
      builder: (context, currencySnapshot) {
        if (currencySnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final currency = currencySnapshot.data ?? 'PKR';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            title: Text(
              "Your Savings",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(color: textColor),
            elevation: 2,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('savings')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No savings yet.",
                    style: TextStyle(
                      fontSize: 18,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              final savings = snapshot.data!.docs;

              return ListView.builder(
                itemCount: savings.length,
                itemBuilder: (context, index) {
                  final saving = savings[index];
                  final docId = saving.id;
                  final name = saving['name'];
                  final amount = (saving['amount'] as num).toDouble();
                  final date = saving['date'];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                    color: cardColor,
                    child: ListTile(
                      leading: Icon(Icons.savings, color: iconColor, size: 30),
                      title: Text(
                        name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      subtitle: Text(
                        "$currency ${amount.toStringAsFixed(2)}\nSaved on $date",
                        style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => editSavingDialog(context, docId, name, amount, date),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteSaving(docId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => deleteAllSavings(context),
            label: Text("Delete All"),
            icon: Icon(Icons.delete_forever),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
}
