import 'package:flutter/material.dart' hide DateUtils;
import 'package:period_tracker/core/core.dart';
import 'package:period_tracker/features/calendar/models/calendar_model.dart';
import 'package:period_tracker/features/dashboard/viewmodels/dashboard_viewmodel.dart';

class CalendarViewModel extends ChangeNotifier {
  final DashboardViewModel _dashboardViewModel;
  DateTime _currentMonth;
  
  CalendarViewModel(this._dashboardViewModel) : _currentMonth = DateTime.now();
  
  DateTime get currentMonth => _currentMonth;
  
  void setMonth(DateTime month) {
    _currentMonth = DateTime(month.year, month.month);
    notifyListeners();
  }
  
  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    notifyListeners();
  }
  
  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    notifyListeners();
  }
  
  List<DateTime> getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];
    
    for (int i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }
    return days;
  }
  
  List<CalendarEvent> getEventsForDate(DateTime date) {
    final events = <CalendarEvent>[];
    
    if (_dashboardViewModel.isPredictedPeriodDay(date)) {
      final isConfirmed = _dashboardViewModel.cycleModel.periodDates.any(
        (d) => DateUtils.isSameDay(d, date),
      );
      events.add(CalendarEvent(
        id: 'period_${date.millisecondsSinceEpoch}',
        date: date,
        title: isConfirmed ? 'Period' : 'Predicted Period',
        type: CalendarEventType.period,
        color: isConfirmed ? AppTheme.periodColor : AppTheme.periodColor.withValues(alpha: 0.5),
      ));
    }
    
    if (_dashboardViewModel.isPredictedOvulationDay(date)) {
      events.add(CalendarEvent(
        id: 'ovulation_${date.millisecondsSinceEpoch}',
        date: date,
        title: 'Ovulation',
        type: CalendarEventType.ovulation,
        color: AppTheme.ovulationColor,
      ));
    } else if (_dashboardViewModel.isPredictedFertileDay(date)) {
      events.add(CalendarEvent(
        id: 'fertile_${date.millisecondsSinceEpoch}',
        date: date,
        title: 'Fertile Window',
        type: CalendarEventType.fertile,
        color: AppTheme.fertileColor,
      ));
    }
    
    final symptoms = _dashboardViewModel.getSymptomsForDate(date);
    if (symptoms.isNotEmpty) {
      events.add(CalendarEvent(
        id: 'symptoms_${date.millisecondsSinceEpoch}',
        date: date,
        title: 'Symptoms: ${symptoms.join(', ')}',
        type: CalendarEventType.symptom,
        color: Colors.orange,
      ));
    }
    
    final activities = _dashboardViewModel.getActivitiesForDate(date);
    if (activities.isNotEmpty) {
      events.add(CalendarEvent(
        id: 'activities_${date.millisecondsSinceEpoch}',
        date: date,
        title: 'Activities: ${activities.join(', ')}',
        type: CalendarEventType.activity,
        color: Colors.blue,
      ));
    }
    
    return events;
  }
  
  CalendarMonth getCurrentMonthData() {
    final days = getDaysInMonth(_currentMonth);
    final events = <DateTime, List<CalendarEvent>>{};
    
    for (final day in days) {
      events[day] = getEventsForDate(day);
    }
    
    return CalendarMonth(
      month: _currentMonth,
      days: days,
      events: events,
    );
  }
  
  bool isToday(DateTime date) {
    return DateUtils.isSameDay(date, DateTime.now());
  }
  
  bool isSelected(DateTime date, DateTime selectedDate) {
    return DateUtils.isSameDay(date, selectedDate);
  }
}