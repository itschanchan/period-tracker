// HealthLogsViewModel - Manages flow intensity, pain tracking, and database sync.
// Extracted from CycleViewModel to provide a focused view model for health_logger.dart.
import 'package:flutter/material.dart';
import 'package:clock/clock.dart';
import 'dart:io'; // Added to catch SocketException
import '../services/database_service.dart';
import '../models/daily_log.dart';

class HealthLogsViewModel extends ChangeNotifier {
  // Flow Intensity Labels (moved from CycleViewModel)
  static const List<String> flowIntensityLabels = [
    "Very Light",
    "Light",
    "Moderate",
    "Heavy",
    "Super Heavy",
  ];

  final DatabaseService _dbService = DatabaseService();

  // State management for database operations
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Track state changes to force UI rebuilds when decorations need refreshing
  DateTime _lastUpdated = clock.now();
  DateTime get lastUpdated => _lastUpdated;

  // Flow and Pain tracking
  final Map<DateTime, double> _flowLogs = {};
  final Map<DateTime, int> _painLogs = {};

  /// Initializes the provider by loading data from a persistent source.
  /// Call this when the app starts.
  Future<void> initializeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final logs = await _dbService.fetchDailyLogs();

      for (var log in logs) {
        final date = log.date;

        if (log.flowIntensity != null) {
          final intensity = log.flowIntensity!;
          final index = flowIntensityLabels.indexOf(intensity);
          if (index != -1) {
            _flowLogs[date] = index.toDouble();
          }
        }

        if (log.painLevel != null) {
          _painLogs[date] = log.painLevel!;
        }
      }
    } on SocketException catch (e) {
      debugPrint("Network Error (Check your connection/IP): ${e.message}");
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns a unique set of all dates that have flow or pain data logged.
  Set<DateTime> get loggedHealthDates => {
    ..._flowLogs.keys,
    ..._painLogs.keys,
  };

  // Flow and Pain management
  double getFlowForDate(DateTime date) =>
      _flowLogs[DateUtils.dateOnly(date)] ?? 2.0;
  int getPainForDate(DateTime date) => _painLogs[DateUtils.dateOnly(date)] ?? 0;

  void updateFlow(DateTime date, double value) {
    final normalizedDate = DateUtils.dateOnly(date);
    _flowLogs[normalizedDate] = value;
    _lastUpdated = clock.now();
    notifyListeners();

    // Persist to Database
    _syncDailyLog(normalizedDate);
  }

  void updatePain(DateTime date, int value) {
    final normalizedDate = DateUtils.dateOnly(date);
    _painLogs[normalizedDate] = value;
    _lastUpdated = clock.now();
    notifyListeners();

    // Persist to Database
    _syncDailyLog(normalizedDate);
  }

  /// Syncs the current state of flow and pain for a specific date to the database.
  Future<void> _syncDailyLog(DateTime date) async {
    final flowValue = getFlowForDate(date);
    final painValue = getPainForDate(date);

    // Map flowValue (double 0-4) to String label
    final flowIntensity =
        flowIntensityLabels[flowValue.round().clamp(
          0,
          flowIntensityLabels.length - 1,
        )];

    // Default mood — can be refined by integrating with DailyMonitorViewModel
    String mood = "Normal";

    final log = DailyLogModel(
      date: date,
      flowIntensity: flowIntensity,
      painLevel: painValue,
      mood: mood,
    );

    await _dbService.logTodayData(log);
  }
}
