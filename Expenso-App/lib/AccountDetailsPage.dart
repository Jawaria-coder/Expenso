import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  String userName = 'Loading...';
  String wallet = '0';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      setState(() {
        userName = data['name'] ?? 'No name found';
        wallet = (data['wallet'] ?? '0').toString();
      });
    }
  }

  Future<void> _showEditDialog({
    required String field,
    required String title,
    required String currentValue,
    required TextInputType inputType,
    required Function(String newValue) onSave,
  }) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    final user = FirebaseAuth.instance.currentUser;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            labelText: title,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isEmpty) return;

              if (field == 'wallet') {
                final walletValue = double.tryParse(newValue);
                if (walletValue == null || walletValue < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid: Wallet amount must be a non-negative number.')),
                  );
                  return;
                }
              }

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .set({
                field: field == 'wallet' ? double.parse(newValue) : newValue,
              }, SetOptions(merge: true));

              Navigator.of(context).pop();
              onSave(newValue);
            },

          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user is currently signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Account Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            _buildInfoCard(
              context: context,
              icon: Icons.person,
              label: 'User Name',
              value: userName,
              onTap: () {
                _showEditDialog(
                  field: 'name',
                  title: 'Name',
                  currentValue: userName,
                  inputType: TextInputType.name,
                  onSave: (val) => fetchUserData(),
                );
              },
            ),
            _buildInfoCard(
              context: context,
              icon: Icons.account_balance_wallet,
              label: 'Wallet',
              value: wallet,
              onTap: () {
                _showEditDialog(
                  field: 'wallet',
                  title: 'Wallet',
                  currentValue: wallet,
                  inputType: const TextInputType.numberWithOptions(decimal: true),
                  onSave: (val) => fetchUserData(),
                );
              },
            ),
            _buildInfoCard(
              context: context,
              icon: Icons.lock,
              label: 'Change Password',
              value: '••••••••',
              onTap: () async {
                final currentPasswordController = TextEditingController();
                final newPasswordController = TextEditingController();
                bool obscureCurrent = true;
                bool obscureNew = true;

                await showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) => AlertDialog(
                        title: const Text("Change Password"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: currentPasswordController,
                              obscureText: obscureCurrent,
                              decoration: InputDecoration(
                                labelText: "Current Password",
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureCurrent ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscureCurrent = !obscureCurrent;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: newPasswordController,
                              obscureText: obscureNew,
                              decoration: InputDecoration(
                                labelText: "New Password",
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureNew ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscureNew = !obscureNew;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final currentPassword = currentPasswordController.text.trim();
                              final newPassword = newPasswordController.text.trim();

                              if (newPassword.length < 8) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("New password must be at least 8 characters.")),
                                );
                                return;
                              }

                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                final email = user?.email;
                                if (user != null && email != null) {
                                  final cred = EmailAuthProvider.credential(email: email, password: currentPassword);
                                  await user.reauthenticateWithCredential(cred); // 🔐 Required before updating
                                  await user.updatePassword(newPassword);

                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Password updated successfully.")),
                                  );
                                }
                              } catch (e) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Password change failed: $e")),
                                );
                              }
                            },
                            child: const Text("Update"),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },

            ),
            _buildInfoCard(
              context: context,
              icon: Icons.access_time,
              label: 'Account Created',
              value: user.metadata.creationTime?.toLocal().toString().split(' ').first ?? 'Unknown',
              onTap: () {},
            ),
            _buildInfoCard(
              context: context,
              icon: Icons.login,
              label: 'Last Sign-In',
              value: user.metadata.lastSignInTime?.toLocal().toString().split(' ').first ?? 'Unknown',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
