import 'package:flutter/material.dart';
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
  runApp(MaterialApp(
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
      // home: const GenerateQrScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
