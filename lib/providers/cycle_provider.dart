// Provider - Separates math and data from the UI
import 'package:flutter/material.dart';
import 'package:clock/clock.dart';

class CycleProvider extends ChangeNotifier {
  // Core Application Constants
  static const int defaultCycleLength = 28;
  static const int defaultMensesLength = 5;
  static const int lutealPhaseLength = 14;

  // State management for database operations
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Selected Dates from the Dashboard
  List<DateTime?> _selectedDates = [];
  List<DateTime?> get selectedDates => _selectedDates;

  // Track state changes to force UI rebuilds when decorations need refreshing
  DateTime _lastUpdated = clock.now();
  DateTime get lastUpdated => _lastUpdated;

  // Private variables - these should eventually be loaded from local storage
  DateTime? _lastPeriodDateOverride;
  int _currentCycleLength = defaultCycleLength;
  int _currentMensesLength = defaultMensesLength;
  int _currentLutealPhaseLength = lutealPhaseLength;

  // Logging data: Maps date to a set of items
  final Map<DateTime, Set<String>> _symptomsLog = {};
  final Map<DateTime, Set<String>> _activitiesLog = {};

  /// Initializes the provider by loading data from a persistent source.
  /// Call this when the app starts.
  Future<void> initializeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with repository calls
      // _selectedDates = await repository.getPeriodDates();
      // _symptomsLog = await repository.getSymptoms();
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getter Variables
  // If no period has been manually set, anchor everything to the "mock" today
  DateTime get lastPeriodDate => _lastPeriodDateOverride ?? clock.now();

  int get cycleLength => _currentCycleLength;

  // Exposing menses length so the UI can calculate how many days are remaining in a predicted period.
  int get mensesLength => _currentMensesLength;

  // Calculation: Next Period Date
  DateTime get nextPeriodDate =>
      lastPeriodDate.add(Duration(days: _currentCycleLength));

  // Calculation: Ovulation Day (1-indexed day of the cycle)
  // Logic: cycleLength - lutealPhase
  int get ovulationDayNumber => _currentCycleLength - _currentLutealPhaseLength;

  // Calculation: Ovulation Date (DateTime)
  DateTime get ovulationDate =>
      nextPeriodDate.subtract(Duration(days: _currentLutealPhaseLength));

  // Calculation: Fertile Window
  // Start: 5 days before ovulation
  DateTime get fertileWindowStart =>
      ovulationDate.subtract(const Duration(days: 5));

  // End: The day of ovulation
  DateTime get fertileWindowEnd => ovulationDate;

  /// Updates the user's average cycle and luteal lengths.
  /// This allows the app to "learn" like Flo.
  void updateCycleSettings(int cycle, int luteal) {
    _currentCycleLength = cycle;
    _currentLutealPhaseLength = luteal;
    notifyListeners();
  }

  // Manages symptoms and activities per date logged.
  Set<String> getSymptomsForDate(DateTime date) =>
      _symptomsLog[DateUtils.dateOnly(date)] ?? {};

  Set<String> getActivitiesForDate(DateTime date) =>
      _activitiesLog[DateUtils.dateOnly(date)] ?? {};

  void updateSymptoms(DateTime date, Set<String> symptoms) {
    _symptomsLog[DateUtils.dateOnly(date)] = symptoms;
    notifyListeners();
  }

  void updateActivities(DateTime date, Set<String> activities) {
    _activitiesLog[DateUtils.dateOnly(date)] = activities;
    notifyListeners();
  }

  // Calculation: getter for the firsr recorderd period start.
  // Used for the period_description.dart (Cycle [firstRecordedPeriodStart])
  DateTime? get firstRecordedPeriodStart {
    if (_selectedDates.isEmpty) return null;
    // The _selectedDates are already sorted by updateDates
    return DateTime(
      _selectedDates.first!.year,
      _selectedDates.first!.month,
      _selectedDates.first!.day,
    );
  }

  // Conditional Logic Bounds

  // isRegular: if the cycle is between 21 and 35
  bool get isRegular => _currentCycleLength >= 21 && _currentCycleLength <= 35;

  // isIrregular: if cycle is < 21 or > 35
  bool get isIrregular => _currentCycleLength < 21 || _currentCycleLength > 35;

  // isAverage: if cycle is between 26 and 30
  // bool get isAverage => _currentCycleLength < 26 || _currentCycleLength > 30;

  /// Checks if a date is a predicted period day (recurring)
  bool isPredictedPeriodDay(DateTime date) {
    // Do not show predictions if no dates have been set yet
    if (_selectedDates.isEmpty) return false;

    final anchor = lastPeriodDate;
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(base).inDays;

    // Do not show predictions before the user's history begins.
    final firstStart = firstRecordedPeriodStart;
    if (firstStart != null && target.isBefore(firstStart)) return false;

    // Use modulo to find the day within the cycle (0 to cycleLength - 1)
    final dayInCycle =
        ((difference % _currentCycleLength) + _currentCycleLength) %
        _currentCycleLength;
    return dayInCycle >= 0 && dayInCycle < _currentMensesLength;
  }

  /// Checks if a date is within the predicted fertile window (recurring)
  bool isPredictedFertileDay(DateTime date) {
    // Do not show predictions if no dates have been set yet
    if (_selectedDates.isEmpty) return false;

    final anchor = lastPeriodDate;
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(base).inDays;

    // Do not show predictions before the user's history begins.
    final firstStart = firstRecordedPeriodStart;
    if (firstStart != null && target.isBefore(firstStart)) return false;

    final dayInCycle =
        ((difference % _currentCycleLength) + _currentCycleLength) %
        _currentCycleLength;
    final ovulation = ovulationDayNumber;

    // Flo uses a wider window (approx. 6 days before and 4 days after) to
    // account for sperm longevity and cycle variability.
    const int preOvulationBuffer = 6;
    const int postOvulationBuffer = 4;

    return dayInCycle >= (ovulation - preOvulationBuffer) &&
        dayInCycle <= (ovulation + postOvulationBuffer);
  }

  /// Returns the 1-indexed day of the cycle for a given date.
  int getDayInCycle(DateTime date) {
    if (_selectedDates.isEmpty) return 0;
    final anchor = lastPeriodDate;
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(base).inDays;

    return (((difference % _currentCycleLength) + _currentCycleLength) %
            _currentCycleLength) +
        1;
  }

  /// Checks if a date is the predicted ovulation day (recurring)
  bool isPredictedOvulationDay(DateTime date) {
    // Do not show predictions if no dates have been set yet
    if (_selectedDates.isEmpty) return false;

    final anchor = lastPeriodDate;
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(base).inDays;

    // Do not show predictions before the user's history begins.
    final firstStart = firstRecordedPeriodStart;
    if (firstStart != null && target.isBefore(firstStart)) return false;

    final dayInCycle =
        ((difference % _currentCycleLength) + _currentCycleLength) %
        _currentCycleLength;
    return dayInCycle == ovulationDayNumber;
  }

  /// Adds a single date to the selected dates list and updates calculations.
  /// This ensures confirming a prediction simply appends it to the history.
  void addDate(DateTime date) {
    if (!_selectedDates.any((d) => d != null && DateUtils.isSameDay(d, date))) {
      updateDates([..._selectedDates, date]);
    }
  }

  // updateDates() method
  // Method to update the full list of selected dates from the calendar
  void updateDates(List<DateTime?> dates) {
    // 1. Filter and sort dates to ensure they are chronological.
    final validDates = dates.whereType<DateTime>().toList();
    validDates.sort();
    _selectedDates = validDates;

    // 2. Identify period "blocks" to find start dates and calculate averages.
    if (validDates.isNotEmpty) {
      List<DateTime> periodStarts = [validDates.first];
      List<int> mensesLengths = [];

      for (int i = 1; i < validDates.length; i++) {
        // If there is a gap of more than 1 day, it's a new period block.
        if (validDates[i].difference(validDates[i - 1]).inDays > 1) {
          periodStarts.add(validDates[i]);
        }
      }

      // Calculate average menses length (how many days the period lasts)
      for (int i = 0; i < periodStarts.length; i++) {
        int length = validDates
            .where(
              (d) =>
                  d.isAtSameMomentAs(periodStarts[i]) ||
                  (d.isAfter(periodStarts[i]) &&
                      (i == periodStarts.length - 1 ||
                          d.isBefore(periodStarts[i + 1]))),
            )
            .length;
        mensesLengths.add(length);
      }

      // The latest start date anchors our future predictions.
      _lastPeriodDateOverride = periodStarts.last;

      // 3. Dynamic Learning: Calculate average cycle length.
      // We need at least two periods to calculate an interval.
      if (periodStarts.length >= 2) {
        int totalDays = 0;
        for (int i = 1; i < periodStarts.length; i++) {
          totalDays += periodStarts[i].difference(periodStarts[i - 1]).inDays;
        }

        int average = (totalDays / (periodStarts.length - 1)).round();

        // Apply safety bounds (e.g., normal cycles are 21-35 days).
        if (average >= 21 && average <= 45) {
          _currentCycleLength = average;
        }

        // Update average menses length
        double avgMenses =
            mensesLengths.reduce((a, b) => a + b) / mensesLengths.length;
        _currentMensesLength = avgMenses.round();
      }
    }

    _lastUpdated = clock.now();
    notifyListeners();
  }
}
