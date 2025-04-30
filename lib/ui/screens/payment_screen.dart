import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:xsaev/core/constants.dart';
import 'package:xsaev/domain/services/bluetooth_service.dart';

class PaymentScreen extends StatelessWidget {
  final Map<String, dynamic> details;

  const PaymentScreen({super.key, required this.details});

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
                    data: jsonEncode(details),
                    version: QrVersions.auto,
                    size: 240,
                    gapless: false,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Account: ${details['account']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Item: ${details['item']}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Price: \$${details['price']}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  if (details['imagePath'] != null &&
                      details['imagePath'] != '')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(details['imagePath']),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () async {
                      await BluetoothTransferService().sendPaymentOverBluetooth(
                        details['account'],
                        double.tryParse(details['price']) ?? 0.0,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment Successful!')),
                      );
                      Navigator.pop(context);
                      // Navigator.popUntil(context, (route) => route.isFirst);
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
