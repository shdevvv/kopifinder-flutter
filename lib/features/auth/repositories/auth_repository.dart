import '../../../core/network/api_client.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final SupabaseService _supabase = SupabaseService.instance;

  bool get isAuthenticated => _supabase.isAuthenticated;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (_supabase.isInitialized) {
      await _supabase.signInWithEmail(email: email, password: password);
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    bool registeredViaApi = false;

    // 1. Prioritaskan registrasi via backend admin agar email terkonfirmasi langsung dan tersinkron ke public.users
    try {
      final res = await ApiClient.instance.post(
        '/auth/register',
        body: {
          'email': email.trim(),
          'password': password,
          'full_name': name.trim(),
          'username': username.trim().toLowerCase(),
        },
      );
      if (res != null) {
        registeredViaApi = true;
      }
    } catch (e) {
      if (e is ApiException) {
        throw Exception(e.message);
      }
      // Jika backend tidak dapat dihubungi, lanjutkan ke fallback Supabase langsung
    }

    // 2. Fallback jika backend offline
    if (!registeredViaApi && _supabase.isInitialized) {
      await _supabase.signUp(
        email: email,
        password: password,
        name: name,
        username: username,
      );
    }

    // 3. Login otomatis setelah daftar agar session & currentUser langsung aktif
    if (_supabase.isInitialized) {
      try {
        await _supabase.signInWithEmail(email: email, password: password);
      } catch (_) {
        // Jika butuh konfirmasi email manual dari setting Supabase
      }
    }
  }

  Future<void> signOut() async {
    await _supabase.signOut();
  }

  Future<void> resetPassword(String email) async {
    if (_supabase.isInitialized) {
      await _supabase.resetPassword(email);
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
