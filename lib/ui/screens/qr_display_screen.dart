import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsaev/core/constants.dart';
import 'package:xsaev/data/models/transaction.dart';
import 'package:xsaev/data/models/user.dart';
import 'package:xsaev/domain/services/wifi_service.dart';

class QrDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const QrDisplayScreen({super.key, required this.data});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen>
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

    wifiService.discover();
  }

  void _setupMessageListener() {
    wifiService.messages.listen((message) async {
      // print('my message: $message');
      if (message.contains('amount')) {
        final data = jsonDecode(message);
        print(data);
        await _updateWalletBalance(
          data['amount'],
          data['account'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Received!')),
        );
        Navigator.pop(context);
      }

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

// receiveString: (msg) async {
//           final data = jsonDecode(msg);
//           snack("Received wallet tx: $data");
//           // Example: Update balance
//           final amount = double.tryParse(data['amount']) ?? 0.0;
//           await _updateWalletBalance(amount, data['account']);

//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content: Text('Received \$$amount from ${data['account']}')),
//           );
//           // Navigator.pop(context);
//         },

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

    return ListenableBuilder(
        listenable: wifiService,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Generated Code'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("PEERS: ${wifiService.peers.length}"),
                  SizedBox(
                    height: 100,
                    width: MediaQuery.of(context).size.width,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: wifiService.peers.length,
                      itemBuilder: (context, index) => Center(
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Center(
                                child: AlertDialog(
                                  content: SizedBox(
                                    height: 200,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "name: ${wifiService.peers[index].deviceName}"),
                                        Text(
                                            "address: ${wifiService.peers[index].deviceAddress}"),
                                        Text(
                                            "isGroupOwner: ${wifiService.peers[index].isGroupOwner}"),
                                        Text(
                                            "isServiceDiscoveryCapable: ${wifiService.peers[index].isServiceDiscoveryCapable}"),
                                        Text(
                                            "primaryDeviceType: ${wifiService.peers[index].primaryDeviceType}"),
                                        Text(
                                            "secondaryDeviceType: ${wifiService.peers[index].secondaryDeviceType}"),
                                        Text(
                                            "status: ${wifiService.peers[index].status}"),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        await wifiService.connect(wifiService
                                            .peers[index].deviceAddress);

                                        await wifiService.startSocket();

                                        await wifiService.connectToSocket();
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("connect"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Center(
                              child: Text(
                                wifiService.peers[index].deviceName
                                    .toString()
                                    .characters
                                    .first
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
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
                ],
              ),
            ),
            floatingActionButton: wifiService.peers.isEmpty
                ? ListenableBuilder(
                    listenable: wifiService,
                    builder: (context, _) {
                      return FloatingActionButton(
                        onPressed: () async {
                          await wifiService.discover();

                          await wifiService.closeSocket();
                          await wifiService.createGroup();
                        },
                        backgroundColor: primaryColor,
                        child: const Icon(
                          Icons.sync,
                          color: Colors.white,
                        ),
                      );
                    })
                : null,
          );
        });
  }
}
