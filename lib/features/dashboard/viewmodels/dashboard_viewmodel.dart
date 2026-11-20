// DashboardViewModel - Main view model for the dashboard feature
import 'package:flutter/material.dart' hide DateUtils;
import 'package:clock/clock.dart';
import 'package:period_tracker/core/core.dart';
import 'package:period_tracker/features/dashboard/models/cycle_model.dart';
import 'package:period_tracker/data/data.dart';

class DashboardViewModel extends ChangeNotifier {
  final CycleRepository _repository;
  
  DashboardViewModel({CycleRepository? repository}) 
      : _repository = repository ?? CycleRepositoryImpl(CycleLocalDataSource(PrefsUtils.instance));
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  CycleModel _cycleModel = const CycleModel();
  CycleModel get cycleModel => _cycleModel;
  
  DateTime _lastUpdated = clock.now();
  DateTime get lastUpdated => _lastUpdated;
  
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final cycleData = _repository.getCycleData();
      final userSettings = _repository.getUserSettings();
      
      if (cycleData != null) {
        _cycleModel = _cycleModel.copyWith(
          periodDates: List<DateTime>.from(cycleData['periodDates'] ?? []),
          symptomsLog: _deserializeLog(cycleData['symptomsLog']),
          activitiesLog: _deserializeLog(cycleData['activitiesLog']),
        );
      }
      
      if (userSettings != null) {
        _cycleModel = _cycleModel.copyWith(
          cycleLength: userSettings['cycleLength'] ?? 28,
          mensesLength: userSettings['mensesLength'] ?? 5,
          lutealPhaseLength: userSettings['lutealPhaseLength'] ?? 14,
        );
      }
      
      _recalculateFromDates();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Map<DateTime, Set<String>> _deserializeLog(dynamic data) {
    if (data == null) return {};
    final Map<DateTime, Set<String>> result = {};
    (data as Map<String, dynamic>).forEach((key, value) {
      result[DateTime.parse(key)] = Set<String>.from(value);
    });
    return result;
  }
  
  Map<String, dynamic> _serializeLog(Map<DateTime, Set<String>> log) {
    final Map<String, dynamic> result = {};
    log.forEach((key, value) {
      result[key.toIso8601String().split('T')[0]] = value.toList();
    });
    return result;
  }
  
  void _recalculateFromDates() {
    final dates = _cycleModel.periodDates;
    if (dates.isEmpty) return;
    
    final sortedDates = [...dates]..sort();
    final periodStarts = <DateTime>[sortedDates.first];
    final mensesLengths = <int>[];
    
    for (int i = 1; i < sortedDates.length; i++) {
      if (sortedDates[i].difference(sortedDates[i - 1]).inDays > 1) {
        periodStarts.add(sortedDates[i]);
      }
    }
    
    for (int i = 0; i < periodStarts.length; i++) {
      final start = periodStarts[i];
      final end = i == periodStarts.length - 1 
          ? sortedDates.last 
          : periodStarts[i + 1].subtract(const Duration(days: 1));
      final length = end.difference(start).inDays + 1;
      mensesLengths.add(length);
    }
    
    _cycleModel = _cycleModel.copyWith(
      lastPeriodDate: periodStarts.last,
      mensesLength: mensesLengths.isNotEmpty 
          ? (mensesLengths.reduce((a, b) => a + b) / mensesLengths.length).round()
          : _cycleModel.mensesLength,
    );
    
    if (periodStarts.length >= 2) {
      int totalDays = 0;
      for (int i = 1; i < periodStarts.length; i++) {
        totalDays += periodStarts[i].difference(periodStarts[i - 1]).inDays;
      }
      final average = (totalDays / (periodStarts.length - 1)).round();
      if (average >= 21 && average <= 45) {
        _cycleModel = _cycleModel.copyWith(cycleLength: average);
      }
    }
  }
  
  DateTime get lastPeriodDate => _cycleModel.lastPeriodDate ?? clock.now();
  
  int get cycleLength => _cycleModel.cycleLength;
  int get mensesLength => _cycleModel.mensesLength;
  int get lutealPhaseLength => _cycleModel.lutealPhaseLength;
  
  DateTime get nextPeriodDate => lastPeriodDate.add(Duration(days: cycleLength));
  
  int get ovulationDayNumber => cycleLength - lutealPhaseLength;
  DateTime get ovulationDate => nextPeriodDate.subtract(Duration(days: lutealPhaseLength));
  DateTime get fertileWindowStart => ovulationDate.subtract(const Duration(days: 5));
  DateTime get fertileWindowEnd => ovulationDate;
  
  bool get isRegular => cycleLength >= 21 && cycleLength <= 35;
  bool get isIrregular => cycleLength < 21 || cycleLength > 35;
  
  DateTime? get firstRecordedPeriodStart {
    if (_cycleModel.periodDates.isEmpty) return null;
    return _cycleModel.periodDates.first;
  }
  
  bool isPredictedPeriodDay(DateTime date) {
    if (_cycleModel.periodDates.isEmpty) return false;
    
    final anchor = lastPeriodDate;
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(base).inDays;
    
    final firstStart = firstRecordedPeriodStart;
    if (firstStart != null && target.isBefore(firstStart)) return false;
    
    final dayInCycle = ((difference % cycleLength) + cycleLength) % cycleLength;
    return dayInCycle >= 0 && dayInCycle < mensesLength;
  }
  
  bool isPredictedFertileDay(DateTime date) {
    if (_cycleModel.periodDates.isEmpty) return false;
    
    final anchor = lastPeriodDate;
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(base).inDays;
    
    final firstStart = firstRecordedPeriodStart;
    if (firstStart != null && target.isBefore(firstStart)) return false;
    
    final dayInCycle = ((difference % cycleLength) + cycleLength) % cycleLength;
    const int preOvulationBuffer = 6;
    const int postOvulationBuffer = 4;
    
    return dayInCycle >= (ovulationDayNumber - preOvulationBuffer) &&
        dayInCycle <= (ovulationDayNumber + postOvulationBuffer);
  }
  
  bool isPredictedOvulationDay(DateTime date) {
    if (_cycleModel.periodDates.isEmpty) return false;
    
    final anchor = lastPeriodDate;
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(base).inDays;
    
    final firstStart = firstRecordedPeriodStart;
    if (firstStart != null && target.isBefore(firstStart)) return false;
    
    final dayInCycle = ((difference % cycleLength) + cycleLength) % cycleLength;
    return dayInCycle == ovulationDayNumber;
  }
  
  int getDayInCycle(DateTime date) {
    if (_cycleModel.periodDates.isEmpty) return 0;
    final anchor = lastPeriodDate;
    final base = DateTime(anchor.year, anchor.month, anchor.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(base).inDays;
    
    return (((difference % cycleLength) + cycleLength) % cycleLength) + 1;
  }
  
  Set<String> getSymptomsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _cycleModel.symptomsLog[normalizedDate] ?? {};
  }
  
  Set<String> getActivitiesForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _cycleModel.activitiesLog[normalizedDate] ?? {};
  }
  
  void updateCycleSettings(int cycle, int luteal) {
    _cycleModel = _cycleModel.copyWith(
      cycleLength: cycle,
      lutealPhaseLength: luteal,
    );
    _saveUserSettings();
    notifyListeners();
  }
  
  void updateSymptoms(DateTime date, Set<String> symptoms) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final newLog = Map<DateTime, Set<String>>.from(_cycleModel.symptomsLog);
    newLog[normalizedDate] = symptoms;
    _cycleModel = _cycleModel.copyWith(symptomsLog: newLog);
    _saveCycleData();
    notifyListeners();
  }
  
  void updateActivities(DateTime date, Set<String> activities) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final newLog = Map<DateTime, Set<String>>.from(_cycleModel.activitiesLog);
    newLog[normalizedDate] = activities;
    _cycleModel = _cycleModel.copyWith(activitiesLog: newLog);
    _saveCycleData();
    notifyListeners();
  }
  
  void addDate(DateTime date) {
    if (!_cycleModel.periodDates.any((d) => DateUtils.isSameDay(d, date))) {
      updateDates([..._cycleModel.periodDates, date]);
    }
  }
  
  void updateDates(List<DateTime> dates) {
    final validDates = [...dates]..sort();
    _cycleModel = _cycleModel.copyWith(periodDates: validDates);
    _recalculateFromDates();
    _saveCycleData();
    _lastUpdated = clock.now();
    notifyListeners();
  }
  
  Future<void> _saveCycleData() async {
    await _repository.saveCycleData({
      'periodDates': _cycleModel.periodDates.map((d) => d.toIso8601String()).toList(),
      'symptomsLog': _serializeLog(_cycleModel.symptomsLog),
      'activitiesLog': _serializeLog(_cycleModel.activitiesLog),
    });
  }
  
  Future<void> _saveUserSettings() async {
    await _repository.saveUserSettings({
      'cycleLength': _cycleModel.cycleLength,
      'mensesLength': _cycleModel.mensesLength,
      'lutealPhaseLength': _cycleModel.lutealPhaseLength,
    });
  }
  
  CyclePrediction getPrediction() {
    return CyclePrediction(
      nextPeriodDate: nextPeriodDate,
      ovulationDate: ovulationDate,
      ovulationDayNumber: ovulationDayNumber,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
      isRegular: isRegular,
      isIrregular: isIrregular,
    );
  }
  
  DayInfo getDayInfo(DateTime date, DateTime today) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    return DayInfo(
      date: date,
      dayInCycle: getDayInCycle(date),
      isPeriodDay: isPredictedPeriodDay(date),
      isFertileDay: isPredictedFertileDay(date),
      isOvulationDay: isPredictedOvulationDay(date),
      isPastUnconfirmed: isPredictedPeriodDay(date) && 
          !_cycleModel.periodDates.any((d) => DateUtils.isSameDay(d, date)) &&
          normalizedDate.isBefore(normalizedToday) &&
          !DateUtils.isSameDay(date, today),
      isToday: DateUtils.isSameDay(date, today),
      symptoms: getSymptomsForDate(date),
      activities: getActivitiesForDate(date),
    );
  }
}