import 'package:flutter/material.dart';
import '../../../app/navigation/main_navigation.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/screens/sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isAuthenticated = AuthRepository.instance.isAuthenticated;
    final targetScreen = isAuthenticated
        ? const MainNavigation()
        : const SignInScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => targetScreen,
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
            Image.asset(
              'assets/icons/app_icon.jpeg',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF795548),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
