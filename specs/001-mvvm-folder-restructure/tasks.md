# Implementation Tasks: MVVM Folder Restructure

**Branch**: `001-mvvm-folder-restructure` | **Date**: 2026-10-23 | **Spec**: specs/001-mvvm-folder-restructure/spec.md

---

## Phase 1: Setup

- [x] T001 Create constitutional folder structure per MVVM architecture
  - Create `lib/core/network/` directory
  - Create `lib/data/repositories/` directory
  - Create `lib/features/dashboard/models/` directory
  - Create `lib/features/dashboard/viewModels/` directory
  - Create `lib/features/calendar/models/` directory
  - Create `lib/features/calendar/viewModels/` directory
  - Create `lib/features/onboarding/models/` directory
  - Create `lib/features/onboarding/viewModels/` directory
  - Create `lib/features/settings/models/` directory
  - Create `lib/features/settings/viewModels/` directory
  - Create `lib/data/models/` directory

- [x] T002 Add config.json to pubspec.yaml assets
  - Edit `pubspec.yaml` to include `config.json` under `flutter.assets`

- [x] T003 Add config.json to .gitignore
  - Edit `.gitignore` to add `config.json` and `lib/core/config.json`

---

## Phase 2: Foundational (Blocking Prerequisites)

- [x] T004 Create ConfigService contract and implementation in `lib/core/network/config_service.dart`
  - Implement singleton pattern with `ConfigService.instance`
  - Implement `load()` method: loads `config.json` from assets via `rootBundle.loadString()`
  - Implement `getFirebaseOptions()`: builds platform-specific `FirebaseOptions` from loaded config
  - Implement `getSupabaseConfig()`: returns `SupabaseConfig` with url and anonKey
  - Implement `getFirebaseConfig(platform)`: returns `FirebaseConfig` for specific platform
  - Add validation: throw `ConfigError.missingFile` if config.json not in assets
  - Add validation: throw `ConfigError.malformedJson` on JSON parse failure
  - Add validation: throw `ConfigError.missingRequiredField(field, platform)` for missing required fields
  - Add validation: throw `ConfigError.unsupportedPlatform` if current platform not in config
  - Required fields per platform: apiKey, appId, messagingSenderId, projectId, storageBucket (all); authDomain, measurementId (web, windows); iosBundleId (ios, macos)

- [x] T005 Create ConfigService unit tests in `test/core/network/config_service_test.dart`
  - Test valid config loads correctly and builds FirebaseOptions for each platform
  - Test missing config.json throws ConfigError.missingFile
  - Test malformed JSON throws ConfigError.malformedJson
  - Test missing required field throws ConfigError.missingRequiredField
  - Test unsupported platform throws ConfigError.unsupportedPlatform

- [x] T006 Create config.json.example template in repo root
  - Include firebase object with web, android, ios, macos, windows platform configs
  - Include all required fields as descriptive placeholders (e.g., "YOUR_WEB_API_KEY")
  - Include supabase object with url and anonKey placeholders

- [x] T007 Create repository interfaces in `lib/data/repositories/repositories.dart`
  - AuthRepository: authStateChanges, signInWithEmail, registerWithEmail, signOut, sendPasswordResetEmail, getCurrentUser
  - DatabaseRepository: getDailyLogs, getDailyLog, saveDailyLog, deleteDailyLog, getPeriodDays
  - NotificationRepository: initialize, schedulePeriodReminder, cancelPeriodReminder, requestPermissions
  - AuthException hierarchy: invalidCredentials, userNotFound, emailAlreadyInUse, weakPassword, networkError, unknown

---

## Phase 3: User Story 1 - Eliminate Non-Compliant `backend/` Folder (P1)

**Goal**: Completely remove `lib/backend/` folder and verify zero references remain

**Independent Test**: `lib/backend/` does not exist; `grep -r "package:period_tracker/backend/" lib/` returns zero results

- [x] T008 [US1] Delete `lib/backend/` directory and all contents
  - Remove `lib/backend/models/`, `lib/backend/services/`, `lib/backend/viewModels/`, `lib/backend/firebase_options.dart`

- [x] T009 [US1] Verify no backend imports remain in codebase
  - Run `grep -r "package:period_tracker/backend/" lib/` — must return zero results
  - Fix any remaining imports by updating to new locations

---

## Phase 4: User Story 2 - Relocate Data Models to Constitutional Homes (P1)

**Goal**: Move all models from `lib/backend/models/` to `lib/data/` (shared) or `lib/features/*/models/` (feature-specific)

**Independent Test**: Each model file exists in new location; all imports resolve correctly

- [x] T010 [P] [US2] Move `lib/data/user.dart` → `lib/data/models/user.dart`
  - Update imports in all files referencing User model
  - Fields: uid (String, non-empty, Firebase UID format), email (String, valid email), displayName (String?), photoURL (String?), createdAt (DateTime), lastLoginAt (DateTime)
  - Validation: uid non-empty, email valid format

- [x] T011 [P] [US2] Move `lib/data/daily_log.dart` → `lib/features/dashboard/models/daily_log.dart`
  - Update imports in all files referencing DailyLog
  - Fields: id (String, non-empty), userId (String, non-empty), date (DateTime, date only, not future), flowIntensity (FlowIntensity enum: light, medium, heavy, spotting), symptoms (List<Symptom>), notes (String?), createdAt (DateTime), updatedAt (DateTime)
  - Validation: id non-empty, userId non-empty, date not in future, flowIntensity valid enum

- [x] T012 [P] [US2] Move `lib/data/period_day.dart` → `lib/features/calendar/models/period_day.dart`
  - Update imports in all files referencing PeriodDay
  - Also create copy in `lib/features/dashboard/models/period_day.dart` (shared between dashboard and calendar per assumptions)
  - Fields: date (DateTime, date-only), isPeriodDay (bool), flowIntensity (FlowIntensity?), isPredicted (bool), cycleDay (int?, positive if present)
  - Validation: date date-only, cycleDay positive if present

- [x] T013 [P] [US2] Move `lib/backend/models/onboard_item.dart` → `lib/features/onboarding/models/onboard_item.dart`
  - Update imports in all files referencing OnboardItem
  - Fields: id (String, non-empty), title (String), description (String), imageAsset (String), order (int, >=0)
  - Validation: id non-empty, order >= 0

- [x] T014 [US2] Create barrel exports for models
  - Create `lib/data/models/models.dart` exporting User
  - Create `lib/features/dashboard/models/models.dart` exporting DailyLog, PeriodDay
  - Create `lib/features/calendar/models/models.dart` exporting PeriodDay
  - Create `lib/features/onboarding/models/models.dart` exporting OnboardItem
  - Update `lib/data/data.dart` to export models
  - Update `lib/features/dashboard/dashboard.dart` to export models
  - Update `lib/features/calendar/calendar.dart` to export models
  - Update `lib/features/onboarding/onboarding.dart` to export models

---

## Phase 5: User Story 3 - Relocate Services to Repositories or Core Utilities (P1)

**Goal**: Move services from `lib/backend/services/` to `lib/data/repositories/` (data access) or `lib/core/utils/` / feature ViewModels (app services)

**Independent Test**: Each service has new home; all imports resolve

- [x] T015 [P] [US3] Create `lib/data/repositories/auth_repository_impl.dart` implementing AuthRepository
  - Migrate logic from `lib/backend/services/auth_service.dart`
  - Use Firebase Auth SDK for signInWithEmail, registerWithEmail, signOut, sendPasswordResetEmail, getCurrentUser
  - Expose authStateChanges stream from FirebaseAuth.instance.authStateChanges()
  - Map Firebase User to domain User model
  - Throw AuthException variants per contract (invalidCredentials, userNotFound, emailAlreadyInUse, weakPassword, networkError, unknown)

- [x] T016 [P] [US3] Create `lib/data/repositories/database_repository_impl.dart` implementing DatabaseRepository
  - Migrate logic from `lib/backend/services/database_service.dart`
  - Use Cloud Firestore for getDailyLogs, getDailyLog, saveDailyLog, deleteDailyLog, getPeriodDays
  - Map Firestore documents to DailyLog and PeriodDay models
  - Handle Firestore queries with proper indexing

- [x] T017 [P] [US3] Create `lib/core/utils/notification_service.dart` implementing NotificationRepository
  - Migrate logic from `lib/backend/services/notification_service.dart`
  - Use flutter_local_notifications and firebase_messaging
  - Implement initialize (request permissions, setup channels)
  - Implement schedulePeriodReminder, cancelPeriodReminder, requestPermissions

- [x] T018 [US3] Create barrel export for repositories
  - Create `lib/data/repositories/repositories.dart` exporting AuthRepository, DatabaseRepository, NotificationRepository, and implementations
  - Update `lib/data/data.dart` to export repositories

---

## Phase 6: User Story 4 - Relocate ViewModels to Feature Folders (P1)

**Goal**: Move ViewModels from `lib/backend/viewModels/` to respective feature's `viewModels/` folder

**Independent Test**: Each ViewModel exists in correct feature folder; all imports resolve

- [ ] T019 [P] [US4] Move `lib/backend/viewModels/daily_monitor_view_model.dart` → `lib/features/dashboard/viewModels/daily_monitor_view_model.dart`
  - Update imports to use new model/repository locations
  - Implement DailyMonitorViewModelState with: todayLog (DailyLog?), isLoading (bool), error (String?), selectedFlow (FlowIntensity), selectedSymptoms (List<Symptom>), notes (String)
  - Use DatabaseRepository for saveDailyLog, getDailyLog
  - Use ChangeNotifier for state management
  - All async operations wrapped in try-catch with user-facing error states

- [ ] T020 [P] [US4] Move `lib/backend/viewModels/health_logs_view_model.dart` → `lib/features/dashboard/viewModels/health_logs_view_model.dart`
  - Update imports to use new model/repository locations
  - Implement HealthLogsViewModelState with: logs (List<DailyLog>), isLoading (bool), error (String?), dateRange (DateTimeRange)
  - Use DatabaseRepository for getDailyLogs
  - Use ChangeNotifier for state management
  - All async operations wrapped in try-catch with user-facing error states

- [ ] T021 [US4] Create barrel exports for ViewModels
  - Create `lib/features/dashboard/viewModels/viewModels.dart` exporting DailyMonitorViewModel, HealthLogsViewModel
  - Update `lib/features/dashboard/dashboard.dart` to export viewModels

---

## Phase 7: User Story 5 - Relocate Firebase Options to Core Network (P2)

**Goal**: Move Firebase configuration to `lib/core/network/` with credentials externalized to config.json via ConfigService

**Independent Test**: File exists in core/network; config.json contains platform-specific Firebase config; ConfigService loads at runtime; main.dart initializes Firebase using loaded config

- [ ] T022 [US5] Create `lib/core/network/firebase_options_builder.dart`
  - Build FirebaseOptions from ConfigService.getFirebaseOptions()
  - Platform-specific logic: use defaultTargetPlatform to select correct config
  - Throw descriptive error if platform not supported (linux)

- [ ] T023 [US5] Update `lib/main.dart` to use ConfigService for Firebase initialization
  - Import ConfigService from `package:period_tracker/core/network/config_service.dart`
  - Call `await ConfigService.instance.load()` before `Firebase.initializeApp()`
  - Call `Firebase.initializeApp(options: ConfigService.instance.getFirebaseOptions())`
  - Initialize Supabase with `ConfigService.instance.getSupabaseConfig()`
  - Wrap in try-catch with clear error messaging

- [ ] T024 [US5] Verify firebase_options.dart relocated/updated in `lib/core/network/`
  - Keep generated FlutterFire file as reference (optional)
  - Ensure no hardcoded credentials remain in any .dart file
  - Verify `grep -r "AIzaSy" lib/` returns zero results

---

## Phase 8: User Story 6 - Verify All Imports Resolve and App Builds (P1)

**Goal**: Ensure entire application compiles and runs without errors

**Independent Test**: `flutter analyze` passes with zero errors; `flutter build` succeeds for Android and iOS

- [ ] T025 [US6] Run `flutter analyze` and fix all errors
  - Fix import resolution errors
  - Fix type errors from relocated files
  - Fix any barrel export issues

- [ ] T026 [US6] Run `flutter build apk --debug` and verify success
  - Fix any build-time errors

- [ ] T027 [US6] Run `flutter build ios --debug --no-codesign` and verify success (macOS only)
  - Fix any iOS-specific build issues

- [ ] T028 [US6] Run `flutter build web --debug` and verify success
  - Fix any web-specific build issues

- [ ] T029 [US6] Run `flutter build windows --debug` and verify success
  - Fix any Windows-specific build issues

- [ ] T030 [US6] Run `flutter build macos --debug` and verify success (macOS only)
  - Fix any macOS-specific build issues

---

## Phase 9: Polish & Cross-Cutting Concerns

- [ ] T031 Create `lib/features/settings/models/` and `lib/features/settings/viewModels/` barrel exports
  - Create `lib/features/settings/models/models.dart`
  - Create `lib/features/settings/viewModels/viewModels.dart`
  - Create `lib/features/settings/settings.dart`
  - Update `lib/features/features.dart` to export settings

- [ ] T032 Update `lib/core/core.dart` barrel export to include network/config_service
- [ ] T033 Update `lib/data/data.dart` barrel export to include repositories
- [ ] T034 Update `lib/features/features.dart` barrel export to include all features
- [ ] T035 Add developer onboarding docs for config setup
  - Document in README.md or docs/onboarding.md: copy config.json.example to config.json, fill in values
  - Include required fields for each platform

- [ ] T036 Run full validation suite (quickstart.md scenarios)
  - Scenario 1: Folder structure compliance
  - Scenario 2: Firebase config externalization
  - Scenario 3: Config service loads correctly
  - Scenario 4: Repository pattern implementation
  - Scenario 5: ViewModels in feature folders
  - Scenario 6: Models in constitutional locations
  - Scenario 7: Static analysis passes
  - Scenario 8: Build succeeds (all platforms)
  - Scenario 9: Barrel exports work
  - Scenario 10: Functional parity (smoke test)

---

## Dependency Graph (User Story Completion Order)

```
Phase 1: Setup (T001-T003)
    ↓
Phase 2: Foundational (T004-T007) ← BLOCKS all user stories
    ↓
Phase 3: US1 - Eliminate backend/ (T008-T009)
    ↓
Phase 4: US2 - Relocate Models (T010-T014) ← Can run in parallel with US3, US4
    ↓
Phase 5: US3 - Relocate Services (T015-T018) ← Depends on US2 (models)
    ↓
Phase 6: US4 - Relocate ViewModels (T019-T021) ← Depends on US2, US3
    ↓
Phase 7: US5 - Firebase Config (T022-T024) ← Depends on Foundational (ConfigService)
    ↓
Phase 8: US6 - Verify Build (T025-T030) ← Depends on ALL prior stories
    ↓
Phase 9: Polish (T031-T036)
```

---

## Parallel Execution Examples

### Parallel within US2 (Models) - T010, T011, T012, T013
```bash
# These can run simultaneously - different files, no dependencies between them
# T010: Move User to data/models/
# T011: Move DailyLog to dashboard/models/
# T012: Move PeriodDay to calendar/models/
# T013: Move OnboardItem to onboarding/models/
```

### Parallel within US3 (Services) - T015, T016, T017
```bash
# These can run simultaneously - different repositories, shared interface contracts
# T015: AuthRepositoryImpl
# T016: DatabaseRepositoryImpl
# T017: NotificationService
```

### Parallel within US4 (ViewModels) - T019, T020
```bash
# These can run simultaneously - different ViewModels, same feature
# T019: DailyMonitorViewModel
# T020: HealthLogsViewModel
```

---

## Implementation Strategy

**MVP Scope (Minimum Viable Restructure)**: Complete Phases 1-3 + US2 + US4 + US6
- Eliminate backend/ folder
- Relocate models and ViewModels to constitutional locations
- Update imports and verify build passes
- Defer Firebase config externalization (US5) and full repository pattern (US3) to follow-up

**Incremental Delivery**:
1. **Sprint 1**: Phases 1-2 (Setup + Foundational: ConfigService, repository interfaces, config template)
2. **Sprint 2**: US1 + US2 + US4 (Eliminate backend, relocate models, relocate ViewModels)
3. **Sprint 3**: US3 + US5 (Repository implementations, Firebase config externalization)
4. **Sprint 4**: US6 + Phase 9 (Build verification, polish, validation)

**Risk Mitigation**:
- ConfigService (T004) is critical path — implement and test first
- Staged migration: add new imports before removing old ones
- Keep `lib/backend/` until all imports updated and verified
- Run `flutter analyze` after each major relocation batch

---

## Format Validation

All tasks follow the checklist format:
- ✅ Checkbox: `- [ ]`
- ✅ Task ID: Sequential (T001, T002, ...)
- ✅ [P] marker: Only for parallelizable tasks (different files, no deps)
- ✅ [Story] label: [US1] through [US6] for user story phases only
- ✅ Description: Clear action with exact file paths
- ✅ Setup/Foundational/Polish phases: NO story label
- ✅ User Story phases: MUST have story label