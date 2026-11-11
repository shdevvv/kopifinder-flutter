import 'package:flutter/material.dart';
import 'package:kopifinder/features/auth/screens/sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

  @override
  void initState() {
    super.initState();
    _goToNextPage();
  }

  Future<void> _goToNextPage() async {
    await Future.delayed(const Duration(seconds: 3));

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
      backgroundColor: cream,
      body: Stack(
        children: [
          // DECORATIVE CIRCLES
          Positioned(
            top: -65,
            right: -55,
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -75,
            left: -60,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: sage.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // MAIN CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 125,
                  height: 125,
                  decoration: BoxDecoration(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(38),
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_cafe_rounded,
                    color: Colors.white,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'KopiFinder',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: darkBrown,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Find your perfect coffee spot.',
                  style: TextStyle(
                    fontSize: 14,
                    color: brown,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 45,
                  height: 3,
                  decoration: BoxDecoration(
                    color: sage,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'DISCOVER • EXPLORE • ENJOY',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: brown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '☕  Made for coffee lovers',
                  style: TextStyle(
                    fontSize: 12,
                    color: sage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
