import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsaev/core/constants.dart';
import 'package:xsaev/data/models/user.dart';
import 'package:xsaev/ui/screens/qr_display_screen.dart';
import 'package:xsaev/ui/screens/wfi_transfer.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  final _accountController = TextEditingController();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserAccountNumber();
  }

  Future<void> _loadUserAccountNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson != null) {
      final user = AppUser.fromJson(jsonDecode(userJson));
      _accountController.text = user.accountNumber;
    }
  }

  Future<void> _saveQrCodeData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson != null) {
      final user = AppUser.fromJson(jsonDecode(userJson));
      user.generatedQrCodes.add(jsonEncode(data)); // save QR data as string
      await prefs.setString('userData', jsonEncode(user.toJson()));
    }
  }

  void _generateQR() async {
    if (_accountController.text.isEmpty ||
        _itemController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final Map<String, dynamic> data = {
      'account': _accountController.text,
      'item': _itemController.text,
      'price': _priceController.text,
      'imagePath': _selectedImage?.path ?? '',
    };

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('generatedQrCodes') ?? [];
    existing.add(jsonEncode(data));
    await prefs.setStringList('generatedQrCodes', existing);

    // Navigate to QR Display
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrDisplayScreen(data: data),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Generate Code'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _accountController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(
                Icons.image,
                color: Colors.white,
              ),
              label: const Text(
                'Pick Image',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(_selectedImage!, height: 100),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateQR,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Generate QR Code',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
