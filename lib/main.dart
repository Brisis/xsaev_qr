import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:xsaev/ui/screens/home_screen.dart';
import 'package:xsaev/ui/screens/login_screen.dart';
import 'package:xsaev/ui/screens/profile_screen.dart';
import 'package:xsaev/ui/screens/register_screen.dart';
import 'package:xsaev/ui/screens/splash_screen.dart';
import 'package:xsaev/ui/screens/welcome_screen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/splash',
    routes: {
      '/splash': (context) => const SplashScreen(),
      '/': (context) => const WelcomeScreen(),
      '/register': (context) => const RegisterScreen(),
      '/login': (context) => const LoginScreen(),
      '/home': (context) => const HomeScreen(),
      '/form': (context) => const FormScreen(), // QR generation
      '/scan': (context) => const ScanQrScreen(), // QR scanner
      '/profile': (context) => const ProfileScreen(),
    },
  ));
}

const MaterialColor customGreen = MaterialColor(
  0xFF28a745,
  <int, Color>{
    50: Color(0xFFE1F3E6),
    100: Color(0xFFB3E1BD),
    200: Color(0xFF80CE91),
    300: Color(0xFF4DBB65),
    400: Color(0xFF28A745), // main
    500: Color(0xFF28A745),
    600: Color(0xFF239940),
    700: Color(0xFF1D8938),
    800: Color(0xFF177930),
    900: Color(0xFF0E5C22),
  },
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xsaev',
      theme: ThemeData(
        primarySwatch: customGreen,
      ),
      home: const FormScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _accountController = TextEditingController();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _generateQR() {
    if (_accountController.text.isEmpty ||
        _itemController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    Map<String, dynamic> data = {
      'account': _accountController.text,
      'item': _itemController.text,
      'price': _priceController.text,
      'imagePath': _selectedImage?.path ?? '',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrDisplayScreen(data: data),
      ),
    );
  }

  void _goToScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanQrScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Create QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(labelText: 'Account Number'),
            ),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(_selectedImage!, height: 100),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateQR,
              child: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _goToScanner,
              child: const Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}

class QrDisplayScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const QrDisplayScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    String encoded = jsonEncode(data);
    return Scaffold(
      appBar: AppBar(title: const Text('Your QR Code')),
      body: Center(
        child: QrImageView(
          data: encoded,
          version: QrVersions.auto,
          size: 300.0,
        ),
      ),
    );
  }
}

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      controller.pauseCamera();
      result = scanData;
      if (result != null) {
        Map<String, dynamic> data = jsonDecode(result!.code!);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(details: data),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }
}

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
