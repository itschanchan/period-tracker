class PeriodDayModel {
  final DateTime date;
  final bool isPredicted;

  PeriodDayModel({
    required this.date,
    this.isPredicted = false,
  });

  factory PeriodDayModel.fromJson(Map<String, dynamic> json) {
    return PeriodDayModel(
      date: DateTime.parse(json['date'] as String),
      isPredicted: json['is_predicted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'is_predicted': isPredicted,
    };
  }

  PeriodDayModel copyWith({
    DateTime? date,
    bool? isPredicted,
  }) {
    return PeriodDayModel(
      date: date ?? this.date,
      isPredicted: isPredicted ?? this.isPredicted,
    );
  }

  // To easily check if two models represent the same day
  bool isSameDay(DateTime otherDate) {
    return date.year == otherDate.year &&
           date.month == otherDate.month &&
           date.day == otherDate.day;
  }
}
