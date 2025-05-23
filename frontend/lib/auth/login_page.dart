import 'package:flutter/material.dart';
import 'package:telegram_drive/home/home_page.dart';
import 'package:telegram_drive/shared_preferences.dart/userData.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _showVerification = false;
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _launchTelegramBot() async {
    setState(() => _isLoading = true);

    final httpsUrl = Uri.parse('https://t.me/teledrive77_bot?start=fromapp');
    final tgUrl =
        Uri.parse('tg://resolve?domain=teledrive77_bot&start=fromapp');

    try {
      if (await canLaunchUrl(httpsUrl)) {
        await launchUrl(httpsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(tgUrl)) {
        await launchUrl(tgUrl, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog(
            "Couldn't open Telegram. Please make sure you have Telegram installed.");
        return;
      }

      setState(() {
        _showVerification = true;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorDialog("Error launching Telegram: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    // Get code from single text field
    String code = _otpController.text;

    if (code.length != 6) {
      _showErrorDialog("Please enter the complete 6-digit verification code");
      return;
    }

    setState(() => _isLoading = true);

    final serverUrl = 'http://192.168.29.229:3000/api/verify';

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': code}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        _showSuccessDialog(
          "Authentication successful! Welcome, ${responseData['username']}",
          responseData['telegramId'],
          responseData['username'],
        );
      } else {
        _showErrorDialog(responseData['message'] ?? "Verification failed");
      }
    } catch (e) {
      _showErrorDialog("Error verifying code: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(
      String message, String telegramId, String username) async {
    // Save user data first
    await UserPreferences.saveUserData(
      telegramId: telegramId,
      username: username,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            const Text('Success'),
          ],
        ),
        content: Text('$message\nYour Telegram ID: $telegramId'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [Colors.black, Color(0xFF121212)]
                  : [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _showVerification
                    ? _buildVerificationStep()
                    : _buildInitialStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Logo or Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            size: 60,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'TeleDrive',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Store your files securely using Telegram',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 60),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _launchTelegramBot,
                icon: const Icon(Icons.send),
                label: const Text('Continue with Telegram'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
        const SizedBox(height: 16),
        Text(
          'Free cloud storage for your files',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Telegram-style device illustration
        Image.asset(
          'assets/images/verification_image.png',
          width: 120,
          height: 120,
          // If you don't have this asset, replace with:
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.phone_android,
            size: 100,
            color: Colors.blue.shade200,
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Enter the OTP Below',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            shadows: [
              Shadow(
                blurRadius: 3.0,
                color: Colors.blueAccent.withValues(),
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "We've sent the code to the Telegram app",
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Replace the Row of OTP boxes with a simple text field
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(maxWidth: 360),
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : Colors.grey.shade50,
            child: TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
              decoration: InputDecoration(
                counterText: "",
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                  fontSize: 28,
                  letterSpacing: 8,
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.grey.shade50,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                if (value.length == 6) {
                  _verifyCode();
                }
              },
              controller: _otpController,
            ),
          ),
        ),

        const SizedBox(height: 40),
        _isLoading
            ? const CircularProgressIndicator()
            : Column(
                children: [
                  ElevatedButton(
                    onPressed: _verifyCode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Verify Code'),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showVerification = false;
                        _otpController.clear();
                      });
                    },
                    icon: Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
      ],
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
