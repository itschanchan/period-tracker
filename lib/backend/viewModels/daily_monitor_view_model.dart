// DailyMonitorViewModel - Manages symptoms and activities logging.
// Extracted from CycleViewModel to provide a focused view model for daily_monitor.dart.
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/daily_log.dart';

class DailyMonitorViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // State management
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Logging data: Maps date to a set of items
  final Map<DateTime, Set<String>> _symptomsLog = {};
  final Map<DateTime, Set<String>> _activitiesLog = {};

  /// Returns a unique set of all dates that have symptoms or activities logged.
  Set<DateTime> get loggedHealthDates => {
    ..._symptomsLog.keys,
    ..._activitiesLog.keys,
  };

  // Manages symptoms and activities per date logged.
  Set<String> getSymptomsForDate(DateTime date) =>
      _symptomsLog[DateUtils.dateOnly(date)] ?? {};

  Set<String> getActivitiesForDate(DateTime date) =>
      _activitiesLog[DateUtils.dateOnly(date)] ?? {};

  Future<void> initializeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final logs = await _dbService.fetchDailyLogs();
      for (var log in logs) {
        final date = log.date;
        if (log.symptoms.isNotEmpty) {
          _symptomsLog[date] = log.symptoms.toSet();
        }
        if (log.activities.isNotEmpty) {
          _activitiesLog[date] = log.activities.toSet();
        }
      }
    } catch (e) {
      debugPrint("Error loading daily monitor data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSymptoms(DateTime date, Set<String> symptoms) {
    final normalizedDate = DateUtils.dateOnly(date);
    _symptomsLog[normalizedDate] = symptoms;
    notifyListeners();
    _syncDailyLog(normalizedDate);
  }

  void updateActivities(DateTime date, Set<String> activities) {
    final normalizedDate = DateUtils.dateOnly(date);
    _activitiesLog[normalizedDate] = activities;
    notifyListeners();
    _syncDailyLog(normalizedDate);
  }

  Future<void> _syncDailyLog(DateTime date) async {
    final log = DailyLogModel(
      date: date,
      symptoms: getSymptomsForDate(date).toList(),
      activities: getActivitiesForDate(date).toList(),
    );
    await _dbService.logTodayData(log);
  }
}
