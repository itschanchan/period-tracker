class AppConstants {
  static const String appName = 'Period Tracker';
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int defaultLutealPhase = 14;
  
  static const String prefsKeyCycleData = 'cycle_data';
  static const String prefsKeyUserSettings = 'user_settings';
  static const String prefsKeyFirstLaunch = 'first_launch';
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
}