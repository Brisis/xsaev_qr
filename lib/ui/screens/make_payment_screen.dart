// make_payment_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsaev/core/constants.dart';
import 'package:xsaev/data/models/transaction.dart';
import 'package:xsaev/data/models/user.dart';
import 'package:xsaev/domain/services/nearby_service.dart';
import 'package:xsaev/ui/screens/receive_payment_screen.dart';

class MakePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> details;

  const MakePaymentScreen({super.key, required this.details});

  @override
  State<MakePaymentScreen> createState() => _MakePaymentScreenState();
}

class _MakePaymentScreenState extends State<MakePaymentScreen> {
  final NearbyConnectionsService nearby = NearbyConnectionsService();
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  AppUser? user;
  bool _isReceiving = false;
  bool _isProcessing = true;

  String _statusMessage = 'Waiting for payment...';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _startPaymentListener();
    _setupListeners();
  }

  void _setupListeners() {
    nearby.onConnectionInitiated.listen((event) {
      _showConnectionDialog(event.endpointId, event.info);
    });

    nearby.onConnectionResult.listen((event) {
      _showSnackbar('Connection ${event.status} with ${event.endpointId}');
      if (event.status == 'connected') {
        _sendPaymentData(
          widget.details['account'],
          double.parse(widget.details['price'].toString()),
        );
      }
    });

    nearby.onDisconnected.listen((endpointId) {
      _showSnackbar('Disconnected: $endpointId');
      setState(() {});
    });

    nearby.onPayloadReceived.listen((event) {
      _showSnackbar('Received from ${event.endpointId}: ${event.data}');
    });

    nearby.onPayloadTransferUpdate.listen((event) {
      if (event.update.status == PayloadStatus.SUCCESS) {
        _showSnackbar('Transfer success with ${event.endpointId}');
      }
    });
  }

  void _showConnectionDialog(String endpointId, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ConnectionDialog(
        endpointId: endpointId,
        info: info,
        onAccept: () {
          nearby.acceptConnection(endpointId, info);
          setState(() {
            _isProcessing = false;
          });
        },
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

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson != null) {
      setState(() => user = AppUser.fromJson(jsonDecode(userJson)));
    }
  }

  Future<void> _startPaymentListener() async {
    setState(() {
      _isProcessing = true;
    });
    try {
      Nearby().stopAdvertising();

      await nearby.startAdvertising(userName, strategy);
      _showSnackbar('Advertising started');

      //discovery
      Nearby().stopDiscovery();
      await nearby.startDiscovery(userName, strategy);
      _showSnackbar('Discovery started');
    } catch (e) {
      _showSnackbar('Error: $e');
    }
  }

  Future<void> _sendPaymentData(String receiverAccount, double amount) async {
    try {
      final paymentData = {
        'sender': user!.accountNumber,
        'receiver': receiverAccount,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
        'item': widget.details['item'],
      };

      _showSnackbar(paymentData.toString());
    } on TimeoutException {
    } catch (e) {}
  }

  Future<void> _updateWalletBalance(
      double amount, String receiverAccount) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson == null) return;

    final user = AppUser.fromJson(jsonDecode(userJson));

    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'outgoing',
      amount: amount,
      counterpart: receiverAccount,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StreamBuilder<String>(
              stream: nearby.onEndpointDiscovered,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data!;
                  if (data.startsWith('lost:')) {
                    return Text('Lost endpoint: ${data.substring(5)}');
                  }
                  return ListTile(
                    title: Text('Discovered endpoint: $data'),
                    trailing: ElevatedButton(
                      child: const Text('Connect'),
                      onPressed: () => nearby.requestConnection(userName, data),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 20),
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
                          'Restart Payment',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ElevatedButton(
                      onPressed: _isProcessing || user == null
                          ? null
                          : () {
                              nearby.requestConnection(userName, data);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Confirm Payment',
                              style: TextStyle(color: Colors.white)),
                    );
                  }
                  return ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }),
          ],
        ),
      ),
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
              data: jsonEncode(widget.details),
              size: 240,
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Account:', widget.details['account']),
            _buildDetailRow('Item:', widget.details['item']),
            _buildDetailRow('Price:', '\$${widget.details['price']}'),
            if (widget.details['imagePath'] != null &&
                widget.details['imagePath'].isNotEmpty)
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
          File(widget.details['imagePath']),
          height: 100,
          width: 100,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
