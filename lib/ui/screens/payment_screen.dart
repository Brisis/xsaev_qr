import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsaev/core/constants.dart';
import 'package:xsaev/data/models/transaction.dart';
import 'package:xsaev/data/models/user.dart';
import 'package:xsaev/domain/services/wifi_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> details;

  const PaymentScreen({super.key, required this.details});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  AppUser? user;

  late final WifiService wifiService;

  @override
  void initState() {
    super.initState();
    _loadUser();

    WidgetsBinding.instance.addObserver(this);
    wifiService = WifiService();
    wifiService.initialize();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    wifiService.messages.listen((message) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), duration: const Duration(seconds: 2)));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    wifiService.disposeService();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      wifiService.disposeService();
    } else if (state == AppLifecycleState.resumed) {
      wifiService.initialize();
    }
  }

  void snack(String msg) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          msg,
        ),
      ),
    );
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

  void sendTransfer(String account, double amount) async {
    final data = {
      'account': account,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    };

    wifiService.sendMessage(jsonEncode(data));

    await _updateWalletBalance(amount, account);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful!')),
    );
    Navigator.pop(context);
  }

  Future<void> _updateWalletBalance(double amount, String fromAccount) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson == null) return;

    final user = AppUser.fromJson(jsonDecode(userJson));

    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'outgoing',
      amount: amount,
      counterpart: fromAccount,
      timestamp: DateTime.now(),
    );

    final updatedUser = user.copyWith(
      balance: user.balance - amount,
      transactions: [...user.transactions, newTransaction],
    );
    await prefs.setString('userData', jsonEncode(updatedUser.toJson()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Make a Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: jsonEncode(widget.details),
                    version: QrVersions.auto,
                    size: 240,
                    gapless: false,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Account: ${widget.details['account']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Item: ${widget.details['item']}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Price: \$${widget.details['price']}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  if (widget.details['imagePath'] != null &&
                      widget.details['imagePath'] != '')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(widget.details['imagePath']),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () async {
                      sendTransfer(
                        widget.details['account'],
                        double.tryParse(widget.details['price']) ?? 0.0,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
