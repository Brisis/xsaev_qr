// receive_payment_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsaev/core/constants.dart';
import 'package:xsaev/data/models/transaction.dart';
import 'package:xsaev/data/models/user.dart';
import 'package:xsaev/domain/services/nearby_service.dart';
import 'package:xsaev/ui/screens/home_screen.dart';

class ReceivePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ReceivePaymentScreen({super.key, required this.data});

  @override
  State<ReceivePaymentScreen> createState() => _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends State<ReceivePaymentScreen> {
  final NearbyConnectionsService nearby = NearbyConnectionsService();
  String userName = "Receiver";
  final Strategy strategy = Strategy.P2P_STAR;
  AppUser? user;

  bool _isReceiving = false;
  String _statusMessage = 'Waiting for payment...';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _startPaymentListener();
    _setupListeners();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson != null) {
      setState(() {
        user = AppUser.fromJson(jsonDecode(userJson));
        userName = user?.accountNumber ?? Random().nextInt(10000).toString();
      });
    }
  }

  Future<void> _startPaymentListener() async {
    try {
      await nearby.startAdvertising(userName, strategy);
      // _showSnackbar('Advertising started');

      //discovery
      await nearby.startDiscovery(userName, strategy);
      // _showSnackbar('Discovery started');
    } catch (e) {
      _showSnackbar('Error: $e');
    }
  }

  void _setupListeners() {
    nearby.onConnectionInitiated.listen((event) {
      _showConnectionDialog(event.endpointId, event.info);
    });

    nearby.onConnectionResult.listen((event) {
      // _showSnackbar('Connection ${event.status} with ${event.endpointId}');
    });

    nearby.onDisconnected.listen((endpointId) {
      // _showSnackbar('Disconnected: $endpointId');
      setState(() {});
    });

    nearby.onPayloadReceived.listen((event) {
      // _showSnackbar('Received from ${event.endpointId}: ${event.data}');
      if (event.data.toString().contains("amount")) {
        final data = jsonDecode(event.data);

        _updateWalletBalance(
          data["amount"],
          data["sender"],
        );

        _showSnackbar("Payment received.");

        nearby.stopAll();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });

    nearby.onPayloadTransferUpdate.listen((event) {
      if (event.update.status == PayloadStatus.SUCCESS) {
        // _showSnackbar('Transfer success with ${event.endpointId}');
      }
    });
  }

  void _showConnectionDialog(String endpointId, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ConnectionDialog(
        endpointId: endpointId,
        info: info,
        onAccept: () => nearby.acceptConnection(endpointId, info),
        onReject: () => Nearby().rejectConnection(endpointId),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    nearby.dispose();
    super.dispose();
  }

  Future<void> _updateWalletBalance(double amount, String sender) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson == null) return;

    final user = AppUser.fromJson(jsonDecode(userJson));

    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'incoming',
      amount: amount,
      counterpart: sender,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Payment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // StreamBuilder<String>(
            //   stream: nearby.onEndpointDiscovered,
            //   builder: (context, snapshot) {
            //     if (snapshot.hasData) {
            //       final data = snapshot.data!;
            //       if (data.startsWith('lost:')) {
            //         return Text('Lost endpoint: ${data.substring(5)}');
            //       }
            //       return ListTile(
            //         title: Text('Discovered endpoint: $data'),
            //         trailing: ElevatedButton(
            //           child: const Text('Connect'),
            //           onPressed: () => nearby.requestConnection(userName, data),
            //         ),
            //       );
            //     }
            //     return const SizedBox.shrink();
            //   },
            // ),
            // const SizedBox(height: 20),
            _buildQRCodeSection(),
            const SizedBox(height: 20),
            StreamBuilder<String>(
              stream: nearby.onEndpointDiscovered,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data!;
                  if (data.startsWith('lost:')) {
                    return ElevatedButton(
                      onPressed: () async {
                        await nearby.stopAll();
                        await _startPaymentListener();
                        _setupListeners();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Re-Sync',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ElevatedButton(
                    onPressed: () {
                      nearby.requestConnection(userName, data);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Accept Payment',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                return _buildStatusIndicator();
              },
            ),
          ],
        ),
      ),
      // floatingActionButton: _buildSyncButton(),
    );
  }

  Widget _buildQRCodeSection() {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: jsonEncode(widget.data),
              size: 240,
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Account:', widget.data['account']),
            _buildDetailRow('Item:', widget.data['item']),
            _buildDetailRow('Price:', '\$${widget.data['price']}'),
            if (widget.data['imagePath'] != null &&
                widget.data['imagePath'].isNotEmpty)
              _buildItemImage(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildItemImage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(widget.data['imagePath']),
          height: 100,
          width: 100,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Column(
      children: [
        if (_isReceiving) const CircularProgressIndicator(),
        Text(
          _statusMessage,
          style: TextStyle(
            color: _isReceiving ? Colors.grey : primaryColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // Widget _buildSyncButton() {
  //   return FloatingActionButton(
  //     onPressed: _isReceiving
  //         ? null
  //         : () async {
  //             await _startPaymentListener();
  //           },
  //     backgroundColor: primaryColor,
  //     tooltip: 'Restart Payment Listener',
  //     child: _isReceiving
  //         ? const CircularProgressIndicator(color: Colors.white)
  //         : const Icon(Icons.sync, color: Colors.white),
  //   );
  // }
}

class ConnectionDialog extends StatelessWidget {
  final String endpointId;
  final ConnectionInfo info;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ConnectionDialog({
    super.key,
    required this.endpointId,
    required this.info,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Connection Request from ${info.endpointName}',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          Text('ID: $endpointId'),
          Text('Authentication Token: ${info.authenticationToken}'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onAccept();
                },
                child: const Text('Accept'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onReject();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
