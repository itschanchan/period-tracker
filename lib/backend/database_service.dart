import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  /// Fetches daily logs for the currently authenticated user.
  Future<List<Map<String, dynamic>>> fetchDailyLogs() async {
    try {
      // The RLS policy automatically filters this to only show the logged-in user's data
      final response = await _supabase
          .from('daily_logs')
          .select()
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('Error fetching logs: $error');
      return [];
    }
  }

  /// Inserts or updates daily log data for the current user.
  Future<void> logTodayData({
    required String flowIntensity,
    required int painLevel,
    required String mood,
    DateTime? date,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Operation failed: No authenticated user found.');
        return;
      }

      final targetDate = date ?? DateTime.now();

      await _supabase.from('daily_logs').upsert({
        'user_id': userId,
        'date': targetDate.toIso8601String().split('T')[0], // YYYY-MM-DD
        'flow_intensity': flowIntensity,
        'pain_level': painLevel,
        'mood': mood,
      }, onConflict: 'user_id, date');

      debugPrint('Successfully logged daily data!');
    } catch (error) {
      debugPrint('Error inserting log: $error');
    }
  }

  /// Updates the user's FCM token in their profile.
  /// This token is used to send push notifications to this specific device.
  Future<void> updateFcmToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').upsert({
        'id': userId,
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('FCM Token updated in Supabase');
    } catch (error) {
      debugPrint('Error updating FCM token: $error');
    }
  }
}
