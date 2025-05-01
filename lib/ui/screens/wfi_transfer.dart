import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsaev/core/constants.dart';
import 'package:xsaev/data/models/transaction.dart';
import 'package:xsaev/data/models/user.dart';

class WiFiDirectService {
  final FlutterP2pConnection _plugin = FlutterP2pConnection();
  WifiP2PInfo? wifiInfo;

  Future<void> init() async {
    await _plugin.initialize();
    await _plugin.register();
    _plugin.streamWifiP2PInfo().listen((info) => wifiInfo = info);
  }

  Future<bool> askPermissions() async {
    final granted1 = await _plugin.checkWifiEnabled();
    final granted2 = await _plugin.askStoragePermission();
    return granted1 && granted2;
  }

  Future<void> createGroup() async {
    await _plugin.createGroup(); // Ensure plugin supports this
  }

  Future<bool> discover() => _plugin.discover();

  Future<List<DiscoveredPeers>> getPeers() async {
    await _plugin.discover();
    return await _plugin.fetchPeers(); // Correctly fetch peers
  }

  Future<bool> connect(String deviceAddress) async {
    return (await _plugin.connect(deviceAddress)) ?? false;
  }

  Future<void> startSocket({
    required Function(String msg) onMessage,
    required Function(String name, String address) onConnect,
  }) async {
    if (wifiInfo == null) return;

    await _plugin.startSocket(
      groupOwnerAddress: wifiInfo!.groupOwnerAddress,
      downloadPath: "/storage/emulated/0/Download/",
      onConnect: onConnect,
      // onCloseSocket: () => print("Socket closed."),
      transferUpdate: (_) {},
      receiveString: (msg) async => onMessage(msg),
      maxConcurrentDownloads: 2,
      deleteOnError: true,
    );
  }

  Future<void> connectToSocket({
    required Function(String msg) onMessage,
    required Function(String address) onConnect,
  }) async {
    if (wifiInfo == null) return;

    await _plugin.connectToSocket(
      groupOwnerAddress: wifiInfo!.groupOwnerAddress,
      downloadPath: "/storage/emulated/0/Download/",
      onConnect: onConnect,
      // onCloseSocket: () => print("Closed socket."),
      transferUpdate: (_) {},
      receiveString: (msg) async => onMessage(msg),
      maxConcurrentDownloads: 2,
      deleteOnError: true,
    );
  }

  Future<void> sendMessage(String msg) async {
    await _plugin.sendStringToSocket(msg);
  }

  Future<void> closeSocket() async {
    await _plugin.closeSocket();
  }
}

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> details;

  const PaymentScreen({super.key, required this.details});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  AppUser? user;
  final WiFiDirectService wifiService = WiFiDirectService();

  @override
  void initState() {
    super.initState();
    setupP2P();
    _loadUser();
  }

  void sendTransfer(String account, double amount) async {
    final receiverAddress = widget.details['address'];
    if (receiverAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receiver address missing!')),
      );
      return;
    }

    // Discover and connect
    await wifiService.discover();
    final connected = await wifiService.connect(receiverAddress);
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed!')),
      );
      return;
    }

    // Connect to socket
    await wifiService.connectToSocket(
      onMessage: (msg) {},
      onConnect: (address) => print("Connected to $address"),
    );

    // Send data
    final data = {
      'account': account,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await wifiService.sendMessage(jsonEncode(data));

    // Update UI and data
    await _updateWalletBalance(amount, account);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful!')),
    );
    Navigator.pop(context);
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

  // void sendTransfer(String account, double amount) async {
  //   final data = {
  //     'account': account,
  //     'amount': amount,
  //     'timestamp': DateTime.now().toIso8601String(),
  //   };

  //   wifiService.sendMessage(jsonEncode(data));

  //   await _updateWalletBalance(amount, account);

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Payment Successful!')),
  //   );
  //   Navigator.pop(context);
  // }

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

class QrDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const QrDisplayScreen({super.key, required this.data});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  AppUser? user;
  final WiFiDirectService wifiService = WiFiDirectService();
  late Map<String, dynamic> qrData;

  @override
  void initState() {
    super.initState();
    qrData = Map.from(widget.data);
    setupP2P();
    _loadUser();
    startP2PSocket();
    _listenForGroupAddress();
  }

  void _listenForGroupAddress() {
    wifiService._plugin.streamWifiP2PInfo().listen((info) {
      if (info.groupOwnerAddress != null && mounted) {
        setState(() {
          qrData['address'] = info.groupOwnerAddress;
        });
      }
    });
  }

  void setupP2P() async {
    await wifiService.init();
    await wifiService.askPermissions();
    await wifiService.createGroup(); // Create group to become GO
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
