// Database Repository Implementation
// Location: lib/data/repositories/database_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:period_tracker/features/dashboard/models/daily_log.dart';
import 'package:period_tracker/features/calendar/models/period_day.dart';
import 'repositories.dart';

/// Supabase implementation of DatabaseRepository
class DatabaseRepositoryImpl implements DatabaseRepository {
  /// Resolved lazily so the service can be constructed before (or without)
  /// Supabase being initialised.
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<DailyLogModel>> getDailyLogs(String userId, DateTime start, DateTime end) async {
    try {
      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('daily_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date', ascending: false);

      final rawData = List<Map<String, dynamic>>.from(response);
      return rawData.map((json) => DailyLogModel.fromJson(json)).toList();
    } catch (error) {
      debugPrint('Error fetching daily logs: $error');
      return [];
    }
  }

  @override
  Future<DailyLogModel?> getDailyLog(String userId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('daily_logs')
          .select()
          .eq('user_id', userId)
          .eq('date', dateStr)
          .maybeSingle();

      if (response == null) return null;
      return DailyLogModel.fromJson(response);
    } catch (error) {
      debugPrint('Error fetching daily log: $error');
      return null;
    }
  }

  @override
  Future<void> saveDailyLog(DailyLogModel log) async {
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
        onConflict: 'user_id, date',
      );

      debugPrint('Successfully saved daily log!');
    } catch (error) {
      debugPrint('Error saving daily log: $error');
      rethrow;
    }
  }

  @override
  Future<void> deleteDailyLog(String userId, String logId) async {
    try {
      await _supabase.from('daily_logs').delete().eq('user_id', userId).eq('date', logId);
    } catch (error) {
      debugPrint('Error deleting daily log: $error');
      rethrow;
    }
  }

  @override
  Future<List<PeriodDayModel>> getPeriodDays(String userId, DateTime start, DateTime end) async {
    try {
      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('periods')
          .select('start_date, end_date')
          .eq('user_id', userId)
          .gte('start_date', startStr)
          .lte('start_date', endStr)
          .order('start_date', ascending: true);

      final List<PeriodDayModel> periodDays = [];
      for (final row in response) {
        final start = DateTime.parse(row['start_date']);
        final end = DateTime.parse(row['end_date']);

        for (int i = 0; i <= end.difference(start).inDays; i++) {
          periodDays.add(PeriodDayModel(
            date: start.add(Duration(days: i)),
            isPredicted: false,
          ));
        }
      }
      return periodDays;
    } catch (error) {
      debugPrint('Error fetching period days: $error');
      return [];
    }
  }

  @override
  Future<void> syncFullData(
    String userId, {
    required int cycleLength,
    required int mensesLength,
    required List<DateTime> periodDates,
    required Map<DateTime, double> flowLogs,
    required Map<DateTime, int> painLogs,
    required Map<DateTime, Set<String>> symptomsLog,
    required Map<DateTime, Set<String>> activitiesLog,
  }) async {
    try {
      // 1. Sync Profile (average lengths)
      await _supabase.from('profiles').upsert({
        'id': userId,
        'average_cycle_length': cycleLength,
        'average_period_length': mensesLength,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Sync Periods (Convert flat dates into start/end intervals)
      final List<DateTime> validDates = periodDates.toList()..sort();

      if (validDates.isNotEmpty) {
        List<Map<String, dynamic>> periodsToSync = [];
        DateTime periodStart = validDates.first;

        for (int i = 0; i < validDates.length; i++) {
          bool isLast = i == validDates.length - 1;
          bool isGap =
              !isLast && validDates[i + 1].difference(validDates[i]).inDays > 1;

          if (isGap || isLast) {
            periodsToSync.add({
              'user_id': userId,
              'start_date': periodStart.toIso8601String(),
              'end_date': validDates[i].toIso8601String(),
              'is_predicted': false,
            });
            if (!isLast) periodStart = validDates[i + 1];
          }
        }
        // Upsert periods based on a unique constraint of (user_id, start_date)
        await _supabase
            .from('periods')
            .upsert(periodsToSync, onConflict: 'user_id, start_date');
      }

      // 3. Sync Daily Logs (Flow, Pain, Symptoms, Activities)
      // We'll collect all dates that have any logged data
      final allLoggedDates = {
        ...periodDates,
        ...flowLogs.keys,
        ...painLogs.keys,
        ...symptomsLog.keys,
        ...activitiesLog.keys,
      };

      for (final date in allLoggedDates) {
        final dateStr = date.toIso8601String().split('T')[0];

        // a. Create/Update the Daily Log
        final logResponse = await _supabase
            .from('daily_logs')
            .upsert({
              'user_id': userId,
              'date': dateStr,
              'flow_intensity': _mapFlowToText(
                flowLogs[date] ?? 2.0,
              ),
              'pain_level': painLogs[date] ?? 0,
            }, onConflict: 'user_id, date')
            .select('daily_log_id')
            .single();

        final logId = logResponse['daily_log_id'];
        if (logId == null) {
          debugPrint('Failed to retrieve daily_log_id for $dateStr');
          continue;
        }

        // b. Sync Symptoms
        final symptoms = symptomsLog[date] ?? {};
        if (symptoms.isNotEmpty) {
          await _supabase.from('symptoms').delete().eq('daily_log_id', logId);
          await _supabase
              .from('symptoms')
              .insert(
                symptoms
                    .map((s) => {'daily_log_id': logId, 'symptom': s})
                    .toList(),
              );
        }

        // c. Sync Activities
        final activities = activitiesLog[date] ?? {};
        if (activities.isNotEmpty) {
          await _supabase.from('activities').delete().eq('daily_log_id', logId);
          await _supabase
              .from('activities')
              .insert(
                activities
                    .map((a) => {'daily_log_id': logId, 'activity': a})
                    .toList(),
              );
        }
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
      rethrow;
    }
  }

  String _mapFlowToText(double value) {
    if (value <= 1.0) return 'Light';
    if (value <= 2.0) return 'Moderate';
    return 'Heavy';
  }

  @override
  Future<List<DateTime>> fetchPeriodDates() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // Fetch ranges from the 'periods' table instead of 'profiles'
      final List<dynamic> response = await _supabase
          .from('periods')
          .select('start_date, end_date')
          // RLS automatically filters by user_id, but keeping this is safe.
          .eq('user_id', user.id)
          .order('start_date', ascending: true);

      List<DateTime> allDates = [];
      for (var row in response) {
        DateTime start = DateTime.parse(row['start_date']);
        DateTime end = DateTime.parse(row['end_date']);

        // Expand the start/end range into individual dates
        for (int i = 0; i <= end.difference(start).inDays; i++) {
          allDates.add(start.add(Duration(days: i)));
        }
      }
      return allDates;
    } catch (e) {
      debugPrint('Error fetching period dates: $e');
      return [];
    }
  }
}
