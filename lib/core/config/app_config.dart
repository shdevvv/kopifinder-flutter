class AppConfig {
  AppConfig._();

  /// Base URL for the KopiFinder backend REST API.
  /// Defaults to Android emulator loopback to host port 3000.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  /// Supabase project URL (Public).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );

  /// Supabase public anonymous key (Publishable).
  /// Under NO circumstances should service_role key or Gemini API key be placed here.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder-anon-key',
  );

  /// Returns true if valid Supabase configuration is provided.
  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('placeholder') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('placeholder');
  }
}
