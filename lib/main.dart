import 'package:flutter/material.dart';
import 'features/splash/screens/splash_screen.dart';

void main() {
  runApp(const KopiFinderApp());
}

class KopiFinderApp extends StatelessWidget {
  const KopiFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KopiFinder',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFAF7F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF795548),
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
