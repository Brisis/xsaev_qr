import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsaev/data/models/user.dart';
import 'package:xsaev/ui/screens/transaction_history_screen.dart';
import 'package:xsaev/ui/screens/wallet_topup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson != null) {
      setState(() {
        user = AppUser.fromJson(jsonDecode(userJson));
      });
    }
  }

  Future<void> _updateUserNameEmail(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      final updatedUser = user!.copyWith(name: name, email: email);
      await prefs.setString('userData', jsonEncode(updatedUser.toJson()));
      setState(() => user = updatedUser);
    }
  }

  void _editProfile() {
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name")),
            TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _updateUserNameEmail(nameController.text, emailController.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _changePassword() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                obscureText: true,
                controller: oldPasswordController,
                decoration:
                    const InputDecoration(labelText: "Current Password")),
            TextField(
                obscureText: true,
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: "New Password")),
            TextField(
                obscureText: true,
                controller: confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: "Confirm New Password")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final oldPass = oldPasswordController.text;
              final newPass = newPasswordController.text;
              final confirmPass = confirmPasswordController.text;

              if (oldPass != "123456") {
                _showSnack("Incorrect current password.");
              } else if (newPass.length < 6) {
                _showSnack("New password must be at least 6 characters.");
              } else if (newPass != confirmPass) {
                _showSnack("Passwords do not match.");
              } else {
                Navigator.pop(context);
                _showSnack("Password changed successfully.");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _getInitials(String name) {
    List<String> parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryColor,
                    child: Text(_getInitials(user?.name ?? user!.email),
                        style:
                            const TextStyle(fontSize: 32, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  Text(user!.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(user!.email,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Text("Account Number: ${user!.accountNumber}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("Wallet Balance: \$${user!.balance.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WalletTopUpScreen()));
                      await _loadUser();
                    },
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text("Top Up Wallet"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOption(
                      icon: Icons.edit,
                      title: "Edit Profile",
                      onTap: _editProfile),
                  _buildOption(
                      icon: Icons.lock,
                      title: "Change Password",
                      onTap: _changePassword),
                  _buildOption(
                    icon: Icons.history,
                    title: "Transaction History",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const TransactionHistoryScreen()));
                    },
                  ),
                  _buildOption(
                      icon: Icons.notifications,
                      title: "Notifications",
                      onTap: () {}),
                  _buildOption(
                      icon: Icons.logout,
                      title: "Log Out",
                      onTap: _confirmLogout,
                      color: Colors.red),
                ],
              ),
            ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontSize: 16, color: color)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
