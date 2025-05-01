import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsaev/data/models/transaction.dart';
import 'package:xsaev/data/models/user.dart';
import 'package:xsaev/domain/services/wifi_service.dart';

class QrDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const QrDisplayScreen({super.key, required this.data});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  AppUser? user;
  final WiFiDirectService wifiService = WiFiDirectService();

  @override
  void initState() {
    super.initState();
    setupP2P();
    _loadUser();
    startP2PSocket();
  }

  void setupP2P() async {
    await wifiService.init();
    await wifiService.askPermissions();
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

  void startP2PSocket() {
    wifiService.startSocket(
      onConnect: (name, addr) => print("Connected to $name@$addr"),
      onMessage: (msg) async {
        final data = jsonDecode(msg);
        print("Received wallet tx: $data");
        // Example: Update balance
        final amount = double.tryParse(data['amount']) ?? 0.0;
        await _updateWalletBalance(amount, data['account']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Received \$$amount from ${data['account']}')),
        );
        Navigator.pop(context);
      },
    );
  }

  Future<void> _updateWalletBalance(double amount, String fromAccount) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson == null) return;

    final user = AppUser.fromJson(jsonDecode(userJson));

    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'incoming',
      amount: amount,
      counterpart: fromAccount,
      timestamp: DateTime.now(),
    );

    final updatedUser = user.copyWith(
      balance: user.balance + amount,
      transactions: [...user.transactions, newTransaction],
    );

    await prefs.setString('userData', jsonEncode(updatedUser.toJson()));
  }

//   @override
//   void initState() {
//     super.initState();
//     receiveTx();
//   }

// // Store the service instance to manage lifecycle
//   ReceiverBluetoothService? _receiverService;

//   @override
//   void dispose() {
//     // Stop scanning when the widget is disposed
//     _receiverService?.dispose();
//     super.dispose();
//   }

//   Future<void> receiveTx() async {
//     try {
//       if (!(await FlutterBluePlus.isSupported)) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Bluetooth not available"),
//             backgroundColor: Colors.green,
//           ),
//         );
//         return;
//       }

//       final adapterState = await FlutterBluePlus.adapterState.first;
//       if (adapterState != BluetoothAdapterState.on) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Bluetooth is off"),
//             backgroundColor: Colors.green,
//           ),
//         );
//         return;
//       }

//       _receiverService = ReceiverBluetoothService();
//       await _receiverService!.startScanning((receivedAmount) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                   "Received \$${receivedAmount.toStringAsFixed(2)} via Bluetooth"),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

  @override
  Widget build(BuildContext context) {
    final String encoded = jsonEncode(widget.data);
    final String account = widget.data['account'] ?? '';
    final String item = widget.data['item'] ?? '';
    final String price = widget.data['price'] ?? '';
    final String? imagePath = widget.data['imagePath'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Generated Code'),
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
                    data: encoded,
                    version: QrVersions.auto,
                    size: 240,
                    gapless: false,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Account: $account',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Item: $item',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Price: \$$price',
                    style: const TextStyle(fontSize: 15),
                  ),
                  if (imagePath != null && imagePath.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imagePath),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
