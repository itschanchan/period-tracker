import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// viewModels imports
import '../viewModels/cycle_view_model.dart';
import '../viewModels/health_logs_view_model.dart';
import '../viewModels/daily_monitor_view_model.dart';

// the AuthService class
class AuthService {
  final _supabase = Supabase.instance.client;

  // Inside your AuthService class
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

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  /// Exposes the Supabase auth state stream to allow UI components to react to login/logout events.
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Master sync function to pass all app data to the structured Supabase tables.
  Future<void> syncFullData(
    CycleViewModel provider, {
    HealthLogsViewModel? healthLogs,
    DailyMonitorViewModel? dailyMonitor,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      // 1. Sync Profile (average lengths)
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'average_cycle_length': provider.cycleLength,
        'average_period_length': provider.mensesLength,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Sync Periods (Convert flat dates into start/end intervals)
      final List<DateTime> validDates =
          provider.selectedDates.whereType<DateTime>().toList()..sort();

      if (validDates.isNotEmpty) {
        List<Map<String, dynamic>> periodsToSync = [];
        DateTime periodStart = validDates.first;

        for (int i = 0; i < validDates.length; i++) {
          bool isLast = i == validDates.length - 1;
          bool isGap =
              !isLast && validDates[i + 1].difference(validDates[i]).inDays > 1;

          if (isGap || isLast) {
            periodsToSync.add({
              'user_id': user.id,
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
        ...provider.selectedDates.whereType<DateTime>(),
        if (healthLogs != null) ...healthLogs.loggedHealthDates,
        if (dailyMonitor != null) ...dailyMonitor.loggedHealthDates,
      };

      for (final date in allLoggedDates) {
        final dateStr = date.toIso8601String().split('T')[0];

        // a. Create/Update the Daily Log
        final logResponse = await _supabase
            .from('daily_logs')
            .upsert({
              'user_id': user.id,
              'date': dateStr,
              'flow_intensity': _mapFlowToText(
                healthLogs?.getFlowForDate(date) ?? 2.0,
              ),
              'pain_level': healthLogs?.getPainForDate(date) ?? 0,
            }, onConflict: 'user_id, date')
            .select('daily_log_id')
            .single();

        final logId = logResponse['daily_log_id'];
        if (logId == null) {
          debugPrint('Failed to retrieve daily_log_id for $dateStr');
          continue;
        }

        // b. Sync Symptoms
        final symptoms = dailyMonitor?.getSymptomsForDate(date) ?? {};
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
        final activities = dailyMonitor?.getActivitiesForDate(date) ?? {};
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
