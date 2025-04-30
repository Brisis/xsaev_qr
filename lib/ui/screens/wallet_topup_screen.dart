import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsaev/data/models/transaction.dart';
import 'dart:convert';

import 'package:xsaev/data/models/user.dart';

class WalletTopUpScreen extends StatefulWidget {
  const WalletTopUpScreen({super.key});

  @override
  State<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends State<WalletTopUpScreen> {
  final _amountController = TextEditingController();

  Future<AppUser?> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson != null) {
      return AppUser.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> _saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString('userData', userJson);
  }

  Future<void> _addMoney() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final user = await _loadUser();
    if (user == null) return;

    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'incoming',
      amount: amount,
      counterpart: 'Wallet Top-Up',
      timestamp: DateTime.now(),
    );

    final updatedUser = AppUser(
      name: user.name,
      email: user.email,
      password: user.password,
      accountNumber: user.accountNumber,
      balance: user.balance + amount,
      transactions: [...user.transactions, newTransaction],
      generatedQrCodes: user.generatedQrCodes,
    );

    await _saveUser(updatedUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Wallet topped up with \$${amount.toStringAsFixed(2)}')),
      );
      _amountController.clear();
      setState(() {}); // Refresh UI
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2196F3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Money to Wallet'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addMoney,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Top Up Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
