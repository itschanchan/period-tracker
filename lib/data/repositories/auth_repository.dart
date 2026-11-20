import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  Future<void> signInWithGoogle();
  Future<void> signOut();
  User? get currentUser;
  Stream<AuthState> get onAuthStateChange;
  Future<void> syncFullData(
    String userId, {
    required int cycleLength,
    required int mensesLength,
    required List<DateTime> periodDates,
    required Map<DateTime, double> flowLogs,
    required Map<DateTime, int> painLogs,
    required Map<DateTime, Set<String>> symptomsLog,
    required Map<DateTime, Set<String>> activitiesLog,
  });
  Future<List<DateTime>> fetchPeriodDates();
}

/// Supabase implementation of AuthRepository
class SupabaseAuthRepository implements AuthRepository {
  /// Resolved lazily so the service can be constructed before (or without)
  /// Supabase being initialised.
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<void> signInWithGoogle() async {
    debugPrint('AuthService: Initiating Google Sign In');

    if (kIsWeb) {
      // On Web: Get the OAuth URL and launch it in a NEW TAB ('_blank').
      // This is critical for IDE debug mode where the CanvasKit renderer
      // covers the page with a <canvas> element. Using '_self' would load
      // the Google sign-in page underneath the canvas, making it unclickable.
      // A new tab avoids this entirely. The onAuthStateChange listener will
      // automatically pick up the session when the OAuth redirect completes.
      final res = await _supabase.auth.getOAuthSignInUrl(
        provider: OAuthProvider.google,
        redirectTo: Uri.base.origin,
        queryParams: {'prompt': 'select_account'},
      );
      final url = Uri.parse(res.url);
      await launchUrl(url, webOnlyWindowName: '_blank');
    } else {
      // On mobile: Use the standard OAuth redirect flow.
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.periodtracker://login-callback',
        queryParams: {'prompt': 'select_account'},
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  User? get currentUser {
    try {
      return _supabase.auth.currentUser;
    } catch (_) {
      // Supabase is not initialised (e.g. missing build-time credentials).
      return null;
    }
  }

  @override
  Stream<AuthState> get onAuthStateChange {
    try {
      return _supabase.auth.onAuthStateChange;
    } catch (_) {
      return const Stream<AuthState>.empty();
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
    }
  }

  String _mapFlowToText(double value) {
    if (value <= 1.0) return 'Light';
    if (value <= 2.0) return 'Moderate';
    return 'Heavy';
  }

  @override
  Future<List<DateTime>> fetchPeriodDates() async {
    final user = currentUser;
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