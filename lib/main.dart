import 'package:flutter/material.dart';
import 'package:xsaev/core/constants.dart';
import 'package:xsaev/ui/screens/forgot_password_screen.dart';
import 'package:xsaev/ui/screens/generate_qr_screen.dart';
import 'package:xsaev/ui/screens/home_screen.dart';
import 'package:xsaev/ui/screens/login_screen.dart';
import 'package:xsaev/ui/screens/profile_screen.dart';
import 'package:xsaev/ui/screens/register_screen.dart';
import 'package:xsaev/ui/screens/scan_qr_screen.dart';
import 'package:xsaev/ui/screens/splash_screen.dart';
import 'package:xsaev/ui/screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xsaev',
      theme: ThemeData(
        primarySwatch: customGreen,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor, // Main customGreen color
          iconTheme: IconThemeData(color: Colors.white), // Icon color
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const WelcomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/geneate-qr': (context) => const GenerateQrScreen(), // QR generation
        '/scan': (context) => const ScanQrScreen(), // QR scanner
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
