class UserModel {
  final String id;
  final String? fcmToken;
  final int cycleLength;
  final int mensesLength;
  final int lutealPhaseLength;
  final DateTime? firstRecordedPeriodStart;
  final DateTime? lastPeriodDateOverride;

  UserModel({
    required this.id,
    this.fcmToken,
    this.cycleLength = 28,
    this.mensesLength = 5,
    this.lutealPhaseLength = 14,
    this.firstRecordedPeriodStart,
    this.lastPeriodDateOverride,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fcmToken: json['fcm_token'] as String?,
      cycleLength: json['cycle_length'] as int? ?? 28,
      mensesLength: json['menses_length'] as int? ?? 5,
      lutealPhaseLength: json['luteal_phase_length'] as int? ?? 14,
      firstRecordedPeriodStart: json['first_recorded_period_start'] != null
          ? DateTime.parse(json['first_recorded_period_start'] as String)
          : null,
      lastPeriodDateOverride: json['last_period_date_override'] != null
          ? DateTime.parse(json['last_period_date_override'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fcm_token': fcmToken,
      'cycle_length': cycleLength,
      'menses_length': mensesLength,
      'luteal_phase_length': lutealPhaseLength,
      'first_recorded_period_start': firstRecordedPeriodStart
          ?.toIso8601String(),
      'last_period_date_override': lastPeriodDateOverride?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fcmToken,
    int? cycleLength,
    int? mensesLength,
    int? lutealPhaseLength,
    DateTime? firstRecordedPeriodStart,
    DateTime? lastPeriodDateOverride,
  }) {
    return UserModel(
      id: id ?? this.id,
      fcmToken: fcmToken ?? this.fcmToken,
      cycleLength: cycleLength ?? this.cycleLength,
      mensesLength: mensesLength ?? this.mensesLength,
      lutealPhaseLength: lutealPhaseLength ?? this.lutealPhaseLength,
      firstRecordedPeriodStart:
          firstRecordedPeriodStart ?? this.firstRecordedPeriodStart,
      lastPeriodDateOverride:
          lastPeriodDateOverride ?? this.lastPeriodDateOverride,
    );
  }
}
