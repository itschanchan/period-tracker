import 'package:equatable/equatable.dart';

class CycleModel extends Equatable {
  final DateTime? lastPeriodDate;
  final int cycleLength;
  final int mensesLength;
  final int lutealPhaseLength;
  final List<DateTime> periodDates;
  final Map<DateTime, Set<String>> symptomsLog;
  final Map<DateTime, Set<String>> activitiesLog;

  const CycleModel({
    this.lastPeriodDate,
    this.cycleLength = 28,
    this.mensesLength = 5,
    this.lutealPhaseLength = 14,
    this.periodDates = const [],
    this.symptomsLog = const {},
    this.activitiesLog = const {},
  });

  CycleModel copyWith({
    DateTime? lastPeriodDate,
    int? cycleLength,
    int? mensesLength,
    int? lutealPhaseLength,
    List<DateTime>? periodDates,
    Map<DateTime, Set<String>>? symptomsLog,
    Map<DateTime, Set<String>>? activitiesLog,
  }) {
    return CycleModel(
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      cycleLength: cycleLength ?? this.cycleLength,
      mensesLength: mensesLength ?? this.mensesLength,
      lutealPhaseLength: lutealPhaseLength ?? this.lutealPhaseLength,
      periodDates: periodDates ?? this.periodDates,
      symptomsLog: symptomsLog ?? this.symptomsLog,
      activitiesLog: activitiesLog ?? this.activitiesLog,
    );
  }

  @override
  List<Object?> get props => [
        lastPeriodDate,
        cycleLength,
        mensesLength,
        lutealPhaseLength,
        periodDates,
        symptomsLog,
        activitiesLog,
      ];
}

class CyclePrediction {
  final DateTime nextPeriodDate;
  final DateTime ovulationDate;
  final int ovulationDayNumber;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final bool isRegular;
  final bool isIrregular;

  const CyclePrediction({
    required this.nextPeriodDate,
    required this.ovulationDate,
    required this.ovulationDayNumber,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.isRegular,
    required this.isIrregular,
  });
}

class DayInfo {
  final DateTime date;
  final int dayInCycle;
  final bool isPeriodDay;
  final bool isFertileDay;
  final bool isOvulationDay;
  final bool isPastUnconfirmed;
  final bool isToday;
  final Set<String> symptoms;
  final Set<String> activities;

  const DayInfo({
    required this.date,
    required this.dayInCycle,
    required this.isPeriodDay,
    required this.isFertileDay,
    required this.isOvulationDay,
    required this.isPastUnconfirmed,
    required this.isToday,
    this.symptoms = const {},
    this.activities = const {},
  });
}