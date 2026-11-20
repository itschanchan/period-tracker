class DailyLogModel {
  final DateTime date;
  final String? flowIntensity;
  final int? painLevel;
  final String? mood;
  final List<String> symptoms;
  final List<String> activities;

  DailyLogModel({
    required this.date,
    this.flowIntensity,
    this.painLevel,
    this.mood,
    this.symptoms = const [],
    this.activities = const [],
  });

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      date: DateTime.parse(json['date'] as String),
      flowIntensity: json['flow_intensity'] as String?,
      painLevel: json['pain_level'] as int?,
      mood: json['mood'] as String?,
      symptoms: json['symptoms'] != null
          ? List<String>.from(json['symptoms'])
          : [],
      activities: json['activities'] != null
          ? List<String>.from(json['activities'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'date': date.toIso8601String().split('T')[0],
    };

    if (flowIntensity != null) data['flow_intensity'] = flowIntensity;
    if (painLevel != null) data['pain_level'] = painLevel;
    if (mood != null) data['mood'] = mood;
    if (symptoms.isNotEmpty) data['symptoms'] = symptoms;
    if (activities.isNotEmpty) data['activities'] = activities;

    return data;
  }

  DailyLogModel copyWith({
    DateTime? date,
    String? flowIntensity,
    int? painLevel,
    String? mood,
    List<String>? symptoms,
    List<String>? activities,
  }) {
    return DailyLogModel(
      date: date ?? this.date,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      painLevel: painLevel ?? this.painLevel,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      activities: activities ?? this.activities,
    );
  }
}