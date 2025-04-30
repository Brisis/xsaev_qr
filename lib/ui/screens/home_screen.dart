import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "";
  List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      final user = jsonDecode(userData);
      setState(() {
        userName = user['name'] ?? "User";
        transactions = user['transactions'] ?? [];
      });
    }
  }

  // Future<void> _logout() async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text("Logout"),
  //       content: const Text("Are you sure you want to log out?"),
  //       actions: [
  //         TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: const Text("Cancel")),
  //         TextButton(
  //             onPressed: () => Navigator.pop(context, true),
  //             child: const Text("Logout")),
  //       ],
  //     ),
  //   );

  //   if (confirmed == true) {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setBool('isLoggedIn', false);
  //     if (mounted) {
  //       Navigator.pushReplacementNamed(context, '/login');
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF28a745);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        title: const Text(
          "Xsaev",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon:
                const Icon(Icons.account_circle, color: Colors.white, size: 28),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back, ${userName.split(' ').first} 👋",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Ready to make a quick payment?",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    title: "Generate QR",
                    icon: Icons.qr_code,
                    color: primaryColor,
                    onTap: () => Navigator.pushNamed(context, '/geneate-qr'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionCard(
                    title: "Scan QR",
                    icon: Icons.qr_code_scanner,
                    color: primaryColor,
                    onTap: () => Navigator.pushNamed(context, '/scan'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            const Text(
              "Recent Transactions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            if (transactions.isNotEmpty)
              ...transactions.reversed.map((tx) => _TransactionItem(
                    title: tx['counterpart'],
                    amount: tx['amount'],
                    date: tx['timestamp'].toString().substring(0, 10),
                  ))
            else
              const Text(
                "No transations yet",
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                    fontSize: 16, color: color, fontWeight: FontWeight.w600),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final double amount;
  final String date;

  const _TransactionItem({
    required this.title,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.payment, color: Colors.blueAccent),
        title: Text(title),
        subtitle: Text(date),
        trailing: Text(
          "\$$amount",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
