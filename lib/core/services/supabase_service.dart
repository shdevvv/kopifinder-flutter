import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (!AppConfig.isSupabaseConfigured) {
      developer.log(
        'Supabase configuration contains placeholder values. Running in offline/unconfigured mode.',
        name: 'SupabaseService',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      _initialized = true;

      // Sync existing session token to ApiClient
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        ApiClient.instance.setAuthToken(session.accessToken);
      }

      // Listen to auth state changes to keep ApiClient token fresh
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final token = data.session?.accessToken;
        ApiClient.instance.setAuthToken(token);
      });

      developer.log('Supabase initialized successfully', name: 'SupabaseService');
    } catch (e) {
      developer.log('Failed to initialize Supabase: $e', name: 'SupabaseService');
    }
  }

  SupabaseClient? get client {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }

  User? get currentUser {
    if (!_initialized) return null;
    return Supabase.instance.client.auth.currentUser;
  }

  Session? get currentSession {
    if (!_initialized) return null;
    return Supabase.instance.client.auth.currentSession;
  }

  String? get accessToken {
    return currentSession?.accessToken;
  }

  bool get isAuthenticated {
    return currentUser != null;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_initialized) {
      throw Exception(
        'Supabase belum terkonfigurasi. Pastikan SUPABASE_URL dan SUPABASE_ANON_KEY diatur dengan benar.',
      );
    }
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.session != null) {
      ApiClient.instance.setAuthToken(response.session!.accessToken);
    }
    return response;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    if (!_initialized) {
      throw Exception(
        'Supabase belum terkonfigurasi. Pastikan SUPABASE_URL dan SUPABASE_ANON_KEY diatur dengan benar.',
      );
    }
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'username': username,
      },
    );
    if (response.session != null) {
      ApiClient.instance.setAuthToken(response.session!.accessToken);
    }
    return response;
  }

  Future<void> signOut() async {
    if (_initialized) {
      await Supabase.instance.client.auth.signOut();
    }
    ApiClient.instance.setAuthToken(null);
  }

  Future<void> resetPassword(String email) async {
    if (!_initialized) {
      throw Exception(
        'Supabase belum terkonfigurasi. Pastikan SUPABASE_URL dan SUPABASE_ANON_KEY diatur dengan benar.',
      );
    }
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
  }
}
