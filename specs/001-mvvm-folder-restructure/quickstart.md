# Quickstart Validation Guide: MVVM Folder Restructure

**Date**: 2026-10-23  
**Feature**: 001-mvvm-folder-restructure

---

## Prerequisites

- Flutter SDK 3.x installed
- Dart SDK 3.x installed
- Android Studio / Xcode / VS Code with Flutter extensions
- Firebase project `period-tracker-02b22` with apps configured for all platforms
- Supabase project with URL and anon key

---

## Setup

### 1. Clone and Checkout
```bash
git clone <repo-url>
cd period-tracker
git checkout 001-mvvm-folder-restructure
```

### 2. Create Config File
```bash
# Copy template
cp config.json.example config.json

# Edit with your Firebase/Supabase credentials
# Required fields for each platform:
# - firebase.web.apiKey, appId, messagingSenderId, projectId, authDomain, storageBucket, measurementId
# - firebase.android.apiKey, appId, messagingSenderId, projectId, storageBucket
# - firebase.ios.apiKey, appId, messagingSenderId, projectId, storageBucket, iosBundleId
# - firebase.macos.apiKey, appId, messagingSenderId, projectId, storageBucket, iosBundleId
# - firebase.windows.apiKey, appId, messagingSenderId, projectId, authDomain, storageBucket, measurementId
# - supabase.url, supabase.anonKey
```

### 3. Verify pubspec.yaml Assets
```yaml
# Ensure config.json is listed in flutter.assets:
flutter:
  assets:
    - config.json
```

### 4. Install Dependencies
```bash
flutter pub get
```

---

## Validation Scenarios

### Scenario 1: Folder Structure Compliance
**Goal**: Verify `lib/backend/` eliminated and all files in constitutional locations

**Commands**:
```bash
# Check backend folder gone
test ! -d lib/backend && echo "PASS: lib/backend eliminated" || echo "FAIL: lib/backend exists"

# Check constitutional folders exist
test -d lib/core/network && echo "PASS: core/network exists"
test -d lib/data/repositories && echo "PASS: data/repositories exists"
test -d lib/features/dashboard/models && echo "PASS: features/dashboard/models exists"
test -d lib/features/dashboard/viewModels && echo "PASS: features/dashboard/viewModels exists"
test -d lib/features/calendar/models && echo "PASS: features/calendar/models exists"
test -d lib/features/calendar/viewModels && echo "PASS: features/calendar/viewModels exists"
```

**Expected**: All checks PASS

---

### Scenario 2: Firebase Config Externalization
**Goal**: Verify credentials loaded from config.json, not hardcoded

**Commands**:
```bash
# Verify no hardcoded Firebase credentials in Dart files
! grep -r "AIzaSy" lib/ --include="*.dart" && echo "PASS: No hardcoded API keys" || echo "FAIL: Hardcoded keys found"

# Verify config.json exists in assets (not git)
test -f config.json && echo "PASS: config.json exists locally"
git check-ignore config.json >/dev/null && echo "PASS: config.json gitignored" || echo "FAIL: config.json not gitignored"

# Verify config.json.example exists and tracked
test -f config.json.example && echo "PASS: config.json.example exists"
git ls-files config.json.example >/dev/null && echo "PASS: config.json.example tracked" || echo "FAIL: config.json.example not tracked"
```

**Expected**: All checks PASS

---

### Scenario 3: Config Service Loads Correctly
**Goal**: Verify ConfigService loads config.json and builds FirebaseOptions

**Test**: Run app and verify initialization
```bash
flutter run --debug
```

**Manual Verification**:
1. App launches without config errors
2. Check debug console for: `ConfigService: Configuration loaded successfully`
3. Firebase initializes without "missing API key" errors
4. No hardcoded credential warnings

**Automated Test** (unit):
```bash
flutter test test/core/network/config_service_test.dart
```
**Expected**: All tests PASS

---

### Scenario 4: Repository Pattern Implementation
**Goal**: Verify services relocated to repositories

**Commands**:
```bash
# Check repository interfaces exist
test -f lib/data/repositories/auth_repository.dart && echo "PASS: AuthRepository exists"
test -f lib/data/repositories/database_repository.dart && echo "PASS: DatabaseRepository exists"
test -f lib/data/repositories/notification_repository.dart && echo "PASS: NotificationRepository exists"

# Verify no backend/services imports remain
! grep -r "package:period_tracker/backend/services" lib/ --include="*.dart" && echo "PASS: No backend/services imports" || echo "FAIL: backend/services imports found"
```

**Expected**: All checks PASS

---

### Scenario 5: ViewModels in Feature Folders
**Goal**: Verify ViewModels relocated to features/*/viewModels/

**Commands**:
```bash
test -f lib/features/dashboard/viewModels/daily_monitor_view_model.dart && echo "PASS: DailyMonitorViewModel relocated"
test -f lib/features/dashboard/viewModels/health_logs_view_model.dart && echo "PASS: HealthLogsViewModel relocated"
! grep -r "package:period_tracker/backend/viewModels" lib/ --include="*.dart" && echo "PASS: No backend/viewModels imports" || echo "FAIL: backend/viewModels imports found"
```

**Expected**: All checks PASS

---

### Scenario 6: Models in Constitutional Locations
**Goal**: Verify models relocated to data/ or features/*/models/

**Commands**:
```bash
test -f lib/data/models/user.dart && echo "PASS: User model in data/"
test -f lib/features/dashboard/models/daily_log.dart && echo "PASS: DailyLog in dashboard/models/"
test -f lib/features/calendar/models/period_day.dart && echo "PASS: PeriodDay in calendar/models/"
test -f lib/features/onboarding/models/onboard_item.dart && echo "PASS: OnboardItem in onboarding/models/"
! grep -r "package:period_tracker/backend/models" lib/ --include="*.dart" && echo "PASS: No backend/models imports" || echo "FAIL: backend/models imports found"
```

**Expected**: All checks PASS

---

### Scenario 7: Static Analysis Passes
**Goal**: Verify `flutter analyze` reports zero errors

**Command**:
```bash
flutter analyze
```

**Expected**: 
```
Analyzing period_tracker...
No issues found! (ran in X.Xs)
```

---

### Scenario 8: Build Succeeds
**Goal**: Verify `flutter build` completes for target platforms

**Commands**:
```bash
# Android
flutter build apk --debug

# iOS (requires macOS)
flutter build ios --debug --no-codesign

# Web
flutter build web --debug

# Windows
flutter build windows --debug

# macOS
flutter build macos --debug
```

**Expected**: All builds complete successfully

---

### Scenario 9: Barrel Exports Work
**Goal**: Verify barrel exports expose public APIs correctly

**Commands**:
```bash
# Test imports resolve via barrels
flutter analyze --watch 2>&1 | head -20
# Should show no "unused_import" or "import_of_legacy_library" errors related to restructure
```

**Test Import Pattern** (in a test file):
```dart
// Should work without direct nested imports
import 'package:period_tracker/core/core.dart';
import 'package:period_tracker/data/data.dart';
import 'package:period_tracker/features/dashboard/dashboard.dart';
import 'package:period_tracker/features/calendar/calendar.dart';
```

**Expected**: Imports resolve, no analysis errors

---

### Scenario 10: Functional Parity (Smoke Test)
**Goal**: Verify existing features work identically post-restructure

**Manual Test Checklist**:
- [ ] App launches to dashboard
- [ ] User can sign in / sign up (Firebase Auth)
- [ ] Dashboard displays daily logs
- [ ] Calendar shows period days
- [ ] Notifications can be enabled/scheduled
- [ ] Onboarding flow completes
- [ ] Settings accessible
- [ ] Data persists across app restarts (Hive/SharedPreferences)
- [ ] Firestore sync works (online)

---

## CI/CD Validation

### GitHub Actions / Bitrise / Codemagic
```yaml
# Required checks in CI pipeline:
- flutter analyze
- flutter test
- flutter build apk --release
- flutter build ios --release --no-codesign
- flutter build web --release
```

---

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| `ConfigError.missingFile` | Ensure `config.json` in project root AND listed in `pubspec.yaml` assets |
| `ConfigError.missingRequiredField` | Check `config.json` has all required fields for current platform |
| `FirebaseOptions` construction fails | Verify `ConfigService.getFirebaseOptions()` called after `load()` |
| `flutter analyze` shows import errors | Run `flutter pub get`, check barrel exports (`*.dart` files) exist |
| Build fails with "Firebase not initialized" | Ensure `ConfigService.instance.load()` awaited before `Firebase.initializeApp()` |

---

## Success Criteria Mapping

| Spec Criteria | Validation Scenario |
|---------------|---------------------|
| SC-001: backend eliminated | Scenario 1 |
| SC-002: 100% files relocated | Scenarios 4, 5, 6 |
| SC-003: flutter analyze clean | Scenario 7 |
| SC-004: flutter build succeeds | Scenario 8 |
| SC-005: features functional | Scenario 10 |
| SC-006: no backend imports | Scenarios 4, 5, 6 |
| SC-007: barrel exports work | Scenario 9 |
| SC-008: config.json has Firebase config | Scenario 2 |
| SC-009: no hardcoded credentials | Scenario 2 |
| SC-010: config service validates | Scenario 3 |
| SC-011: config.json gitignored | Scenario 2 |
| SC-012: config.json.example exists | Scenario 2 |
| SC-013: onboarding docs | Manual verification |

---

## Next Steps After Validation

1. All scenarios PASS → Ready for `/speckit.tasks` to generate implementation tasks
2. Any FAIL → Address issues, re-run validation
3. Update spec if any requirements need adjustment