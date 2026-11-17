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
      // Offline / unconfigured development mode: simulate sign in delay
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    if (_supabase.isInitialized) {
      await _supabase.signUp(
        email: email,
        password: password,
        name: name,
        username: username,
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
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
