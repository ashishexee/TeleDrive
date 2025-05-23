import 'package:flutter/material.dart';
import 'package:telegram_drive/auth/login_page.dart';
import 'package:telegram_drive/home/home_page.dart';
import 'package:telegram_drive/shared_preferences.dart/userData.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final isLoggedIn = await UserPreferences.isLoggedIn();
    
    if (mounted) {
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            FlutterLogo(size: 100),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text("TeleDrive", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}