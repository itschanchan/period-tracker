import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:period_tracker/features/dashboard/models/daily_log.dart';

class DatabaseService {
  /// Resolved lazily so the service can be constructed before (or without)
  /// Supabase being initialised.
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Fetches daily logs for the currently authenticated user.
  Future<List<DailyLogModel>> fetchDailyLogs() async {
    try {
      // The RLS policy automatically filters this to only show the logged-in user's data
      final response = await _supabase
          .from('daily_logs')
          .select()
          .order('date', ascending: false);

      final rawData = List<Map<String, dynamic>>.from(response);
      return rawData.map((json) => DailyLogModel.fromJson(json)).toList();
    } catch (error) {
      debugPrint('Error fetching logs: $error');
      return [];
    }
  }

  /// Inserts or updates daily log data for the current user.
  Future<void> logTodayData(DailyLogModel log) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Operation failed: No authenticated user found.');
        return;
      }

      final json = log.toJson();
      json['user_id'] = userId;

      await _supabase.from('daily_logs').upsert(
        json,
        onConflict: 'user_id, date'
      );

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