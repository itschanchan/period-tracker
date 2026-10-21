import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

// Configures Supabase

class SupabaseConfig {
  static SupabaseClient? _client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'Supabase not initialized. Call SupabaseConfig.initialize() first.',
      );
    }
    return _client!;
  }

  static bool get isInitialized => _client != null;
}
