import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDisplayScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const QrDisplayScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String encoded = jsonEncode(data);
    final String account = data['account'] ?? '';
    final String item = data['item'] ?? '';
    final String price = data['price'] ?? '';
    final String? imagePath = data['imagePath'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pushNamed(context, '/home'),
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        title: const Text('Generated Code'),
        backgroundColor: const Color(0xFF2196F3),
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
