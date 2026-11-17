import 'package:flutter/material.dart';
import 'package:kopifinder/features/auth/screens/sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToSignIn();
  }

  Future<void> _goToSignIn() async {
    // Memberikan jeda loading sebelum masuk ke halaman Sign In
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const SignInScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tampilkan artwork logo utuh tanpa membungkusnya dengan bentuk lain.
            Image.asset(
              'assets/icons/app_icon.jpeg',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 28),
            // Loading indicator di bawah logo
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF795548), // Warna cokelat kopi
              ),
            ),
          ],
        ),
      ),
    );
  }
}
