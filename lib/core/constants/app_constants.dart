class AppConstants {
  static const String appName = 'Period Tracker';

  /// Supabase credentials are supplied at build time, e.g.
  /// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
  /// See `docs/securing_api_keys.md`.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int defaultLutealPhase = 14;
  
  static const String prefsKeyCycleData = 'cycle_data';
  static const String prefsKeyUserSettings = 'user_settings';
  static const String prefsKeyFirstLaunch = 'first_launch';
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
}