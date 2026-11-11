import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFAF7F0);
    const lightGreen = Color(0xFFE8EDDF);
    const sageGreen = Color(0xFF9AAA83);
    const darkGreen = Color(0xFF52634A);
    const brown = Color(0xFF795548);
    const darkBrown = Color(0xFF4E342E);

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Cute KopiFinder Logo
              Center(
                child: Container(
                  width: 95,
                  height: 95,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.coffee_rounded,
                        color: darkBrown,
                        size: 53,
                      ),
                      Positioned(
                        top: 9,
                        right: 11,
                        child: Icon(
                          Icons.auto_awesome,
                          color: sageGreen.withOpacity(0.9),
                          size: 20,
                        ),
                      ),
                      const Positioned(
                        bottom: 10,
                        left: 12,
                        child: Icon(
                          Icons.favorite_rounded,
                          color: brown,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'KopiFinder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Your cozy coffee journey starts here ☕',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: darkGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Create an account and start discovering coffee spots.',
                style: TextStyle(
                  fontSize: 14,
                  color: brown,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 25),

              _buildLabel('Full Name', darkBrown),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
              ),

              const SizedBox(height: 18),

              _buildLabel('Username', darkBrown),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _usernameController,
                hint: 'Enter your username',
                icon: Icons.alternate_email_rounded,
              ),

              const SizedBox(height: 18),

              _buildLabel('Email', darkBrown),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 18),

              _buildLabel('Password', darkBrown),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _passwordController,
                hint: 'Create your password',
                isVisible: _isPasswordVisible,
                onToggle: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),

              const SizedBox(height: 18),

              _buildLabel('Confirm Password', darkBrown),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: 'Confirm your password',
                isVisible: _isConfirmPasswordVisible,
                onToggle: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sign Up belum terhubung ke backend.',
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
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: darkBrown,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              const Center(
                child: Text(
                  'Made with love & coffee ♡',
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

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: color,
        fontSize: 14,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const brown = Color(0xFF795548);
    const darkGreen = Color(0xFF52634A);
    const sageGreen = Color(0xFF9AAA83);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: brown.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
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
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    const brown = Color(0xFF795548);
    const darkGreen = Color(0xFF52634A);
    const sageGreen = Color(0xFF9AAA83);

    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: brown.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: darkGreen,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: darkGreen,
          ),
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
    );
  }
}
