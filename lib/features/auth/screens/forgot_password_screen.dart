import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFAF7F0);
    const lightGreen = Color(0xFFE5EBDD);
    const sageGreen = Color(0xFF8A9A75);
    const darkGreen = Color(0xFF52634A);
    const brown = Color(0xFF795548);
    const darkBrown = Color(0xFF4E342E);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: darkBrown,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 25),

              // Cute lock illustration
              Center(
                child: Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(38),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.lock_reset_rounded,
                        color: darkGreen,
                        size: 62,
                      ),
                      Positioned(
                        top: 8,
                        right: 12,
                        child: Icon(
                          Icons.auto_awesome,
                          color: sageGreen.withOpacity(0.8),
                          size: 23,
                        ),
                      ),
                      const Positioned(
                        bottom: 12,
                        left: 13,
                        child: Icon(
                          Icons.favorite_rounded,
                          color: brown,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Forgot Password?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Don’t worry! Enter your email address and '
                'we will send you instructions to reset your password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: brown,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 38),

              const Text(
                'Email Address',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(
                    color: brown.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: darkGreen,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFE4E8DC),
                      width: 1.3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: sageGreen,
                      width: 1.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter your email address.',
                          ),
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password reset belum terhubung ke backend.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: darkGreen.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Send Reset Instructions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(
                    color: brown,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Center(
                child: Text(
                  '☕  Take a little coffee break  ☕',
                  style: TextStyle(
                    color: sageGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
