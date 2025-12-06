import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class ShoppingListDetailsPage extends StatefulWidget {
  final String listId;
  final String title;

  const ShoppingListDetailsPage({
    Key? key,
    required this.listId,
    required this.title,
  }) : super(key: key);

  @override
  State<ShoppingListDetailsPage> createState() =>
      _ShoppingListDetailsPageState();
}

class _ShoppingListDetailsPageState extends State<ShoppingListDetailsPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _allSelected = false;

  final Color customPurple = const Color(0xFF9B59B6);

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  Future<void> _addItem(String itemName) async {
    if (itemName.trim().isEmpty || _currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('shopping_lists')
        .doc(widget.listId)
        .collection('items')
        .add({
      'name': itemName.trim(),
      'checked': false,
      'created_at': Timestamp.now(),
    });

    _controller.clear();
  }

  Future<void> _toggleCheck(String itemId, bool currentValue) async {
    if (_currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('shopping_lists')
        .doc(widget.listId)
        .collection('items')
        .doc(itemId)
        .update({'checked': !currentValue});
  }

  Future<void> _deleteCheckedItems() async {
    if (_currentUser == null) return;

    final itemsRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('shopping_lists')
        .doc(widget.listId)
        .collection('items');

    final snapshot = await itemsRef.where('checked', isEqualTo: true).get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _shareList(List<QueryDocumentSnapshot> items) async {
    final shareItems = items
        .map((e) => "${e['checked'] ? '✅' : '⬜'} ${e['name']}")
        .join('\n');
    Share.share("🛒 ${widget.title}:\n\n$shareItems");
  }

  Future<void> _toggleSelectAll(bool selectAll) async {
    if (_currentUser == null) return;

    final itemsRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('shopping_lists')
        .doc(widget.listId)
        .collection('items');

    final snapshot = await itemsRef.get();

    final batch = _firestore.batch();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'checked': selectAll});
    }

    await batch.commit();

    setState(() {
      _allSelected = selectAll;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: customPurple),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(color: customPurple),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(
              Icons.select_all,
              color: customPurple,
            ),
            tooltip: _allSelected ? 'Unselect All' : 'Select All',
            onPressed: () => _toggleSelectAll(!_allSelected),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_sweep,
              color: customPurple,
            ),
            tooltip: 'Delete checked items',
            onPressed: _deleteCheckedItems,
          ),
        ],
      ),
      body: _currentUser == null
          ? Center(
        child: Text("Please log in to view this list.",
            style: theme.textTheme.bodyMedium),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add item...',
                      hintStyle: GoogleFonts.poppins(
                        color: theme.textTheme.bodyLarge?.color
                            ?.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _addItem,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _addItem(_controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Icon(Icons.add, color: Colors.white),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_currentUser!.uid)
                  .collection('shopping_lists')
                  .doc(widget.listId)
                  .collection('items')
                  .orderBy('created_at', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error loading items.",
                          style: theme.textTheme.bodyMedium));
                }
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final allChecked = items.isNotEmpty &&
                      items.every((doc) => doc['checked'] == true);
                  if (allChecked != _allSelected) {
                    setState(() {
                      _allSelected = allChecked;
                    });
                  }
                });

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      "No items added yet.",
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: customPurple),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(14),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final itemName = doc['name'] ?? '';
                    final checked = doc['checked'] ?? false;

                    return Card(
                      elevation: 3,
                      color: surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: CheckboxListTile(
                        title: Text(
                          itemName,
                          style: GoogleFonts.poppins(
                            color: theme.textTheme.bodyLarge?.color,
                            decoration: checked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        value: checked,
                        onChanged: (val) {
                          _toggleCheck(doc.id, checked);
                        },
                        activeColor: customPurple,
                        checkColor: Colors.white,
                        controlAffinity:
                        ListTileControlAffinity.leading,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () {
                if (_currentUser == null) return;
                final items = _firestore
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .collection('shopping_lists')
                    .doc(widget.listId)
                    .collection('items');
                items.get().then((snapshot) {
                  _shareList(snapshot.docs);
                });
              },
              icon: Icon(Icons.share, color: Colors.white),
              label: Text("Share List",
                  style: GoogleFonts.poppins(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: customPurple,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}