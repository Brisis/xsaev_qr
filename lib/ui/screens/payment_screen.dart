import 'dart:io';

import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final Map<String, dynamic> details;

  const PaymentScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (details['imagePath'] != null && details['imagePath'] != '')
              Image.file(File(details['imagePath']), height: 100),
            Text('Account: ${details['account']}',
                style: const TextStyle(fontSize: 18)),
            Text('Item: ${details['item']}',
                style: const TextStyle(fontSize: 18)),
            Text('Price: \$${details['price']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment Successful!')),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Pay Now'),
            )
          ],
        ),
      ),
    );
  }
}
