import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<void> _resetPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    final email = emailController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (userData == null) {
      _showSnackBar("No user found.");
      return;
    }

    final user = jsonDecode(userData);

    if (email != user['email']) {
      _showSnackBar("Email does not match registered account.");
      _logResetAttempt(success: false);
    } else if (newPassword.length < 6) {
      _showSnackBar("Password must be at least 6 characters.");
    } else if (newPassword != confirmPassword) {
      _showSnackBar("Passwords do not match.");
    } else {
      user['password'] = newPassword;
      await prefs.setString('userData', jsonEncode(user));
      _logResetAttempt(success: true);
      _showSnackBar("Password reset successfully.");
      Navigator.pop(context);
    }
  }

  Future<void> _logResetAttempt({required bool success}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> logs = prefs.getStringList('resetAttempts') ?? [];
    final timestamp = DateTime.now().toIso8601String();
    logs.add("$timestamp - Attempt ${success ? 'Successful' : 'Failed'}");
    await prefs.setStringList('resetAttempts', logs);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2196F3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              const Text("Enter your email and new password below",
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration:
                    const InputDecoration(labelText: 'Registered Email'),
                validator: (value) =>
                    value!.contains('@') ? null : 'Enter a valid email',
              ),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (value) =>
                    value!.length < 6 ? 'Must be at least 6 characters' : null,
              ),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
                validator: (value) => value != newPasswordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _resetPassword();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
