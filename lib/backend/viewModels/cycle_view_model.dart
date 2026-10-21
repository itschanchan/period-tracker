// Provider - Separates math and data from the UI
// CycleViewModel: Manages cycle prediction, date selection, and calendar logic.
import 'package:flutter/material.dart';
import 'package:clock/clock.dart';

// Models - database schemas
import '../models/user.dart';
import '../models/period_day.dart';

class CycleViewModel extends ChangeNotifier {
  // Core Application Constants
  static const int defaultCycleLength = 28;
  static const int defaultMensesLength = 5;
  static const int lutealPhaseLength = 14;

  UserModel _userModel = UserModel(id: 'local_user');
  List<PeriodDayModel> _periodDays = [];

  // Selected Dates from the Dashboard (computed from models)
  List<DateTime?> get selectedDates => _periodDays.map((p) => p.date).toList();

  // Map old variables to the model
  DateTime? get _lastPeriodDateOverride => _userModel.lastPeriodDateOverride;
  set _lastPeriodDateOverride(DateTime? val) {
    _userModel = _userModel.copyWith(lastPeriodDateOverride: val);
  }

  int get _currentCycleLength => _userModel.cycleLength;
  set _currentCycleLength(int val) {
    _userModel = _userModel.copyWith(cycleLength: val);
  }

  int get _currentMensesLength => _userModel.mensesLength;
  set _currentMensesLength(int val) {
    _userModel = _userModel.copyWith(mensesLength: val);
  }

  int get _currentLutealPhaseLength => _userModel.lutealPhaseLength;
  set _currentLutealPhaseLength(int val) {
    _userModel = _userModel.copyWith(lutealPhaseLength: val);
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

  // Calculation: getter for the firsr recorderd period start.
  // Used for the period_description.dart (Cycle [firstRecordedPeriodStart])
  DateTime? get firstRecordedPeriodStart {
    if (_periodDays.isEmpty) return null;
    return DateTime(
      _periodDays.first.date.year,
      _periodDays.first.date.month,
      _periodDays.first.date.day,
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
    if (_periodDays.isEmpty) return false;

    final target = DateUtils.dateOnly(date);

    // 1. Never show a prediction for a day that is already confirmed as a period.
    if (_periodDays.any((p) => DateUtils.isSameDay(p.date, target))) {
      return false;
    }

    final anchor = DateUtils.dateOnly(lastPeriodDate);
    final difference = target.difference(anchor).inDays;

    // 2. Predictions should only be forward-looking from the most recent confirmed period.
    // This prevents "ghost" periods from appearing in the past.
    if (difference < 0) return false;

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
    if (_periodDays.isEmpty) return false;

    final target = DateUtils.dateOnly(date);

    // Do not show fertile predictions on confirmed period days.
    if (_periodDays.any((p) => DateUtils.isSameDay(p.date, target))) {
      return false;
    }

    final anchor = DateUtils.dateOnly(lastPeriodDate);
    final difference = target.difference(anchor).inDays;

    if (difference < 0) return false;

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
    if (_periodDays.isEmpty) return 0;
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
    if (_periodDays.isEmpty) return false;

    final target = DateUtils.dateOnly(date);

    final anchor = DateUtils.dateOnly(lastPeriodDate);
    final difference = target.difference(anchor).inDays;

    // Ovulation is only predicted for current/future cycles.
    if (difference < 0) return false;

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
    if (!_periodDays.any((p) => DateUtils.isSameDay(p.date, date))) {
      updateDates([...selectedDates, date]);
    }
  }

  // updateDates() method
  // Method to update the full list of selected dates from the calendar
  void updateDates(List<DateTime?> dates) {
    // 1. Filter and sort dates to ensure they are chronological.
    final validDates = dates.whereType<DateTime>().toList();
    validDates.sort();

    _periodDays = validDates
        .map((d) => PeriodDayModel(date: d, isPredicted: false))
        .toList();

    // 2. Identify period "blocks" to find start dates and actual durations.
    if (validDates.isNotEmpty) {
      List<DateTime> periodStarts = [];
      List<int> mensesLengths = [];

      periodStarts.add(validDates.first);
      int currentBlockLength = 1;

      for (int i = 1; i < validDates.length; i++) {
        // FIX: Increase gap threshold. A new period cycle doesn't start
        // just because you missed logging for 1 day.
        // We use 4 days as the standard threshold for separate period episodes.
        if (validDates[i].difference(validDates[i - 1]).inDays > 4) {
          mensesLengths.add(currentBlockLength);
          periodStarts.add(validDates[i]);
          currentBlockLength = 1;
        } else {
          currentBlockLength++;
        }
      }
      mensesLengths.add(currentBlockLength);

      // 1. The latest start date anchors our future predictions.
      _lastPeriodDateOverride = periodStarts.last;

      // 2. Update menses length based on the most recent data.
      // We use clamp(defaultMensesLength, 10) so that if you have only
      // selected 1 or 2 days, the app still predicts a full period (5 days)
      // for the future instead of shrinking the prediction.
      if (mensesLengths.isNotEmpty) {
        _currentMensesLength = mensesLengths.last.clamp(
          defaultMensesLength,
          10,
        );
      }

      // 3. Dynamic Learning: Calculate average cycle length (Weighted).
      // We need at least two periods to calculate an interval.
      if (periodStarts.length >= 2) {
        int totalDays = 0;

        // Weighted Average Logic: Most recent cycles are more predictive.
        // We give the most recent interval a higher weight if available.
        if (periodStarts.length == 2) {
          totalDays = periodStarts[1].difference(periodStarts[0]).inDays;
          _currentCycleLength = totalDays.clamp(21, 45);
        } else {
          // Calculate average of the last 3 intervals
          int count = 0;
          double weightedSum = 0;
          double totalWeight = 0;

          for (int i = periodStarts.length - 1; i > 0 && count < 3; i--) {
            int diff = periodStarts[i].difference(periodStarts[i - 1]).inDays;
            double weight =
                1.0 / (periodStarts.length - i); // Higher weight for recent
            weightedSum += (diff * weight);
            totalWeight += weight;
            count++;
          }

          int average = (weightedSum / totalWeight).round();
          if (average >= 21 && average <= 45) {
            _currentCycleLength = average;
          }
        }

        // Refine average menses length over time.
        // LOGIC: If the latest period is only 1 day, it's likely "ongoing".
        // We don't let it drag the average down until the user adds more days.
        List<int> completedPeriods = mensesLengths.where((l) => l > 1).toList();
        if (completedPeriods.isEmpty) completedPeriods = [mensesLengths.last];

        double avgMenses =
            completedPeriods.reduce((a, b) => a + b) / completedPeriods.length;

        // Ensure we never predict a 0 or 1 day period if history suggests otherwise.
        _currentMensesLength = avgMenses.round().clamp(defaultMensesLength, 10);
      }
    }

    notifyListeners();
  }
}
