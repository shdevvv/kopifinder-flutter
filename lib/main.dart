import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }
  runApp(const KopiFinderApp());
}
