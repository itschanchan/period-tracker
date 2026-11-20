# Data Model: MVVM Folder Restructure

**Date**: 2026-10-23  
**Feature**: 001-mvvm-folder-restructure

---

## Entities

### 1. FirebaseConfig (Platform-Specific)

**Source**: `config.json` → `ConfigService` → `FirebaseOptions`

| Field | Type | Required | Platforms | Description |
|-------|------|----------|-----------|-------------|
| apiKey | String | Yes | All | Firebase API key for platform |
| appId | String | Yes | All | Firebase app identifier |
| messagingSenderId | String | Yes | All | FCM sender ID |
| projectId | String | Yes | All | Firebase project ID |
| authDomain | String | No | web, windows | Firebase Auth domain |
| storageBucket | String | Yes | All | Cloud Storage bucket |
| measurementId | String | No | web, windows | Google Analytics measurement ID |
| iosBundleId | String | No | ios, macos | iOS/macOS bundle identifier |

**Validation Rules**:
- All required fields must be non-empty strings
- `projectId` must match across all platforms
- `messagingSenderId` must match across all platforms
- Platform-specific `appId` format validated (contains platform identifier)

**Relationships**:
- One `FirebaseConfig` per platform (web, android, ios, macos, windows)
- Aggregated into `Map<String, FirebaseConfig>` by `ConfigService`

---

### 2. SupabaseConfig

**Source**: `config.json` → `ConfigService`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| url | String | Yes | Supabase project URL (https://xxx.supabase.co) |
| anonKey | String | Yes | Supabase anonymous/public API key |

**Validation Rules**:
- `url` must be valid HTTPS URL ending with `.supabase.co`
- `anonKey` must be non-empty JWT-like string

---

### 3. AppConfig (Root Config)

**Source**: `config.json` → `ConfigService`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| firebase | Map<String, FirebaseConfig> | Yes | Platform-keyed Firebase configs |
| supabase | SupabaseConfig | Yes | Supabase configuration |

**Validation Rules**:
- Must contain `firebase` object with at least one platform
- Must contain `supabase` object
- At minimum, `android` and `ios` platforms required for mobile app

---

### 4. ConfigService (Runtime Service)

**Location**: `lib/core/network/config_service.dart`

| Property/Method | Type | Description |
|-----------------|------|-------------|
| instance | ConfigService | Singleton instance |
| isLoaded | bool | Whether config has been loaded |
| load() | Future<void> | Loads and parses config.json from assets |
| getFirebaseOptions() | FirebaseOptions | Builds platform-specific FirebaseOptions |
| getSupabaseConfig() | SupabaseConfig | Returns Supabase configuration |
| getFirebaseConfig(platform) | FirebaseConfig? | Returns config for specific platform |

**State Transitions**:
```
Uninitialized → Loading → Loaded (success)
                    → Error (throws ConfigError)
```

**Error Types**:
- `ConfigError.missingFile` — config.json not in assets
- `ConfigError.malformedJson` — JSON parse failure
- `ConfigError.missingRequiredField(field, platform)` — required field absent
- `ConfigError.unsupportedPlatform` — current platform not in config

---

### 5. DailyLog (Feature Model)

**Location**: `lib/features/dashboard/models/daily_log.dart` (relocated from `lib/backend/models/`)

| Field | Type | Description |
|-------|------|-------------|
| id | String | Unique identifier (Firestore doc ID) |
| userId | String | Owner user ID |
| date | DateTime | Log date (date only) |
| flowIntensity | FlowIntensity | Enum: light, medium, heavy, spotting |
| symptoms | List<Symptom> | List of symptoms |
| notes | String? | Optional user notes |
| createdAt | DateTime | Creation timestamp |
| updatedAt | DateTime | Last update timestamp |

**Validation Rules**:
- `id` non-empty
- `userId` non-empty
- `date` not in future (relative to device time)
- `flowIntensity` valid enum value

---

### 6. PeriodDay (Feature Model)

**Location**: `lib/features/calendar/models/period_day.dart` (relocated from `lib/backend/models/`)

| Field | Type | Description |
|-------|------|-------------|
| date | DateTime | Calendar date |
| isPeriodDay | bool | Whether period active |
| flowIntensity | FlowIntensity? | Flow level if period day |
| isPredicted | bool | Whether predicted vs actual |
| cycleDay | int? | Day number in cycle |

**Validation Rules**:
- `date` date-only (time component zeroed)
- `cycleDay` positive integer if present

---

### 7. User (Shared Data Model)

**Location**: `lib/data/models/user.dart` (relocated from `lib/backend/models/`)

| Field | Type | Description |
|-------|------|-------------|
| uid | String | Firebase Auth UID |
| email | String | User email |
| displayName | String? | Display name |
| photoURL | String? | Profile photo URL |
| createdAt | DateTime | Account creation |
| lastLoginAt | DateTime | Last login timestamp |

**Validation Rules**:
- `uid` non-empty (Firebase UID format)
- `email` valid email format

---

### 8. OnboardItem (Feature Model)

**Location**: `lib/features/onboarding/models/onboard_item.dart` (relocated from `lib/backend/models/`)

| Field | Type | Description |
|-------|------|-------------|
| id | String | Unique identifier |
| title | String | Onboarding screen title |
| description | String | Onboarding screen description |
| imageAsset | String | Asset path for illustration |
| order | int | Display order |

**Validation Rules**:
- `id` non-empty
- `order` >= 0

---

## Repository Interfaces

### AuthRepository
```dart
abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<User?> signInWithEmail(String email, String password);
  Future<User?> registerWithEmail(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<User?> getCurrentUser();
}
```

### DatabaseRepository
```dart
abstract class DatabaseRepository {
  Future<List<DailyLog>> getDailyLogs(String userId, DateTime start, DateTime end);
  Future<DailyLog?> getDailyLog(String userId, DateTime date);
  Future<void> saveDailyLog(DailyLog log);
  Future<void> deleteDailyLog(String userId, String logId);
  Future<List<PeriodDay>> getPeriodDays(String userId, DateTime start, DateTime end);
}
```

### NotificationRepository
```dart
abstract class NotificationRepository {
  Future<void> initialize();
  Future<void> schedulePeriodReminder(DateTime date);
  Future<void> cancelPeriodReminder();
  Future<bool> requestPermissions();
}
```

---

## ViewModel State Models

### DailyMonitorViewModelState
```dart
class DailyMonitorViewModelState {
  final DailyLog? todayLog;
  final bool isLoading;
  final String? error;
  final FlowIntensity selectedFlow;
  final List<Symptom> selectedSymptoms;
  final String notes;
}
```

### HealthLogsViewModelState
```dart
class HealthLogsViewModelState {
  final List<DailyLog> logs;
  final bool isLoading;
  final String? error;
  final DateTimeRange dateRange;
}
```

---

## Relationships Summary

```
AppConfig
├── firebase: Map<Platform, FirebaseConfig> → FirebaseOptions (per platform)
└── supabase: SupabaseConfig

ConfigService (singleton)
├── load() → AppConfig
├── getFirebaseOptions() → FirebaseOptions (current platform)
└── getSupabaseConfig() → SupabaseConfig

Repository Interfaces (data/repositories/)
├── AuthRepository → User
├── DatabaseRepository → DailyLog, PeriodDay
└── NotificationRepository

Feature Models (features/*/models/)
├── Dashboard: DailyLog, PeriodDay
├── Calendar: PeriodDay
├── Onboarding: OnboardItem
└── Data (shared): User

ViewModels (features/*/viewModels/)
├── Dashboard: DailyMonitorViewModel, HealthLogsViewModel
├── Calendar: CalendarViewModel
├── Onboarding: OnboardingViewModel
└── Settings: SettingsViewModel
```