class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? fcmToken;
  final int cycleLength;
  final int mensesLength;
  final int lutealPhaseLength;
  final DateTime? firstRecordedPeriodStart;
  final DateTime? lastPeriodDateOverride;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.photoURL,
    this.fcmToken,
    this.cycleLength = 28,
    this.mensesLength = 5,
    this.lutealPhaseLength = 14,
    this.firstRecordedPeriodStart,
    this.lastPeriodDateOverride,
    this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String? ?? json['displayName'] as String?,
      photoURL: json['photo_url'] as String? ?? json['photoURL'] as String?,
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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoURL,
      'fcm_token': fcmToken,
      'cycle_length': cycleLength,
      'menses_length': mensesLength,
      'luteal_phase_length': lutealPhaseLength,
      'first_recorded_period_start': firstRecordedPeriodStart
          ?.toIso8601String(),
      'last_period_date_override': lastPeriodDateOverride?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    String? fcmToken,
    int? cycleLength,
    int? mensesLength,
    int? lutealPhaseLength,
    DateTime? firstRecordedPeriodStart,
    DateTime? lastPeriodDateOverride,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      fcmToken: fcmToken ?? this.fcmToken,
      cycleLength: cycleLength ?? this.cycleLength,
      mensesLength: mensesLength ?? this.mensesLength,
      lutealPhaseLength: lutealPhaseLength ?? this.lutealPhaseLength,
      firstRecordedPeriodStart:
          firstRecordedPeriodStart ?? this.firstRecordedPeriodStart,
      lastPeriodDateOverride:
          lastPeriodDateOverride ?? this.lastPeriodDateOverride,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}