class AppConfig {
  AppConfig._();

  /// Base URL for the KopiFinder backend REST API.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://kopifinder-flutter.vercel.app/api/v1',
  );

  /// Supabase project URL (Public).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ymuroowoxbdwlunyteru.supabase.co',
  );

  /// Supabase public anonymous key (Publishable).
  /// Under NO circumstances should service_role key or Gemini API key be placed here.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable__O9yuQe51noVuH-c5Af6oQ_5HbncRWG',
  );

  /// Returns true if valid Supabase configuration is provided.
  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('placeholder') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('placeholder');
  }
}
