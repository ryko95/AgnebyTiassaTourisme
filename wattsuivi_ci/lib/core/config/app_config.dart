class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseKey => supabasePublishableKey.trim().isNotEmpty
      ? supabasePublishableKey
      : supabaseAnonKey;

  static bool get cloudEnabled =>
      supabaseUrl.trim().isNotEmpty && supabaseKey.trim().isNotEmpty;

  static String get modeLabel =>
      cloudEnabled ? 'Cloud Supabase' : 'Local / démonstration';
}
