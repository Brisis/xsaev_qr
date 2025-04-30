import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeneratedCodesScreen extends StatelessWidget {
  const GeneratedCodesScreen({super.key});

  Future<List<Map<String, dynamic>>> _loadGeneratedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final codesJson = prefs.getStringList('generatedQrCodes') ?? [];
    return codesJson
        .map((code) => jsonDecode(code) as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generated Codes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadGeneratedCodes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final codes = snapshot.data ?? [];

          if (codes.isEmpty) {
            return const Center(child: Text('No QR codes generated yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: codes.length,
            itemBuilder: (context, index) {
              final code = codes[index];
              return Card(
                color: Color.fromARGB(255, 231, 231, 231),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading:
                      code['imagePath'] != null && code['imagePath'].isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  8), // You can adjust the radius
                              child: Image.file(
                                File(code['imagePath']),
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.qr_code),
                  title: Text(
                    code['item'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('\$${code['price']}'),
                  // subtitle: Text(
                  //     'Price: \$${code['price']} • Account: ${code['account']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
