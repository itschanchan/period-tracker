import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class CalendarEvent extends Equatable {
  final String id;
  final DateTime date;
  final String title;
  final String? description;
  final CalendarEventType type;
  final Color color;

  const CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    this.description,
    required this.type,
    required this.color,
  });

  @override
  List<Object?> get props => [id, date, title, description, type, color];
}

enum CalendarEventType {
  period,
  fertile,
  ovulation,
  symptom,
  activity,
  custom,
}

class CalendarMonth {
  final DateTime month;
  final List<DateTime> days;
  final Map<DateTime, List<CalendarEvent>> events;

  const CalendarMonth({
    required this.month,
    required this.days,
    required this.events,
  });
}