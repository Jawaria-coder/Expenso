import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'shopping_list_details.dart';

class ShoppingListPage extends StatefulWidget {
  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  final Set<String> _selectedListIds = {};

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  Future<void> _addShoppingList(String name) async {
    if (name.trim().isEmpty || _currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('shopping_lists')
        .add({
      'title': name.trim(),
      'created_at': Timestamp.now(),
    });

    _controller.clear();
  }

  Future<void> _shareSelectedLists(List<DocumentSnapshot> selectedLists) async {
    if (selectedLists.isEmpty) return;

    final listTitles =
    selectedLists.map((doc) => "📋 ${doc['title']}").join('\n');
    Share.share("🛍 Selected Shopping Lists:\n\n$listTitles");
  }

  Future<void> _confirmDelete(List<DocumentSnapshot> selectedLists) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text("Delete Lists", style: GoogleFonts.poppins()),
        content: Text("Are you sure you want to delete the selected lists?",
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF9B59B6)),
            child: Text("Delete",
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && _currentUser != null) {
      for (var doc in selectedLists) {
        await doc.reference.delete();
      }
      setState(() {
        _selectedListIds.clear();
      });
    }
  }

  void _navigateToListPage(String listId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListDetailsPage(listId: listId, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customPurple = Color(0xFF9B59B6);
    final backgroundColor = isDark ? Colors.black : Color(0xFFF5F5F5);
    final cardColor = isDark ? Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Color(0xFFFFFFFF) : Color(0xFF9B59B6), // Back arrow color
        ),
        title: Text(
          'Shopping Lists',
          style: GoogleFonts.poppins(
            color: isDark ? Color(0xFFFFFFFF) : Color(0xFF9B59B6),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: isDark ? Colors.white : Color(0xFF9B59B6),
            ),
            onPressed: () async {
              if (_selectedListIds.isEmpty) return;
              final snapshot = await _firestore
                  .collection('users')
                  .doc(_currentUser!.uid)
                  .collection('shopping_lists')
                  .get();
              final selectedDocs = snapshot.docs
                  .where((doc) => _selectedListIds.contains(doc.id))
                  .toList();
              _shareSelectedLists(selectedDocs);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDark ? Colors.white : Color(0xFF9B59B6),
            ),
            onPressed: () async {
              if (_selectedListIds.isEmpty) return;
              final snapshot = await _firestore
                  .collection('users')
                  .doc(_currentUser!.uid)
                  .collection('shopping_lists')
                  .get();
              final selectedDocs = snapshot.docs
                  .where((doc) => _selectedListIds.contains(doc.id))
                  .toList();
              _confirmDelete(selectedDocs);
            },
          ),
        ],
      ),

      body: _currentUser == null
          ? Center(
        child: Text("Please log in to view your shopping lists.",
            style: GoogleFonts.poppins(color: customPurple)),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.poppins(color: customPurple),
                    decoration: InputDecoration(
                      hintText: 'Create new list...',
                      hintStyle: GoogleFonts.poppins(
                        color: isDark ? Colors.white : customPurple, // 👈 changed here
                      ),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _addShoppingList,
                  ),

                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _addShoppingList(_controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(14),
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
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading lists.",
                        style: GoogleFonts.poppins(
                            color: customPurple)),
                  );
                }
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: customPurple),
                  );
                }

                final lists = snapshot.data!.docs;

                if (lists.isEmpty) {
                  return Center(
                    child: Text("No shopping lists created yet.",
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: customPurple)),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final doc = lists[index];
                    final title = doc['title'] ?? 'Untitled';
                    final isSelected = _selectedListIds.contains(doc.id);

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            activeColor: customPurple,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedListIds.add(doc.id);
                                } else {
                                  _selectedListIds.remove(doc.id);
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _navigateToListPage(
                                  doc.id, title),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: isDark ? Colors.white : customPurple,
                                      ),
                                    ),

                                    Icon(Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey.shade500),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}