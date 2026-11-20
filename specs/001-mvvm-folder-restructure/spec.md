# Feature Specification: MVVM Folder Restructure

**Feature Branch**: `001-mvvm-folder-restructure`

**Created**: 2026-10-22

**Status**: Draft

**Input**: User description: "restructure the folder, refer to the @docs/mvvm_architecture.md for details."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Eliminate Non-Compliant `backend/` Folder (Priority: P1)

The development team needs the `lib/backend/` folder completely removed so that all code resides in constitutional locations per the MVVM architecture document.

**Why this priority**: The `backend/` folder violates the constitutional folder structure (Principle II, III). It creates confusion about where business logic belongs, enables circular dependencies, and makes onboarding difficult.

**Independent Test**: Can be fully tested by verifying `lib/backend/` no longer exists and all its former contents have been relocated to compliant locations.

**Acceptance Scenarios**:

1. **Given** the project has a `lib/backend/` folder with models, services, and viewModels, **When** the restructure is complete, **Then** `lib/backend/` does not exist.
2. **Given** the restructure is complete, **When** searching for imports of `package:period_tracker/backend/`, **Then** zero references remain.

---

### User Story 2 - Relocate Data Models to Constitutional Homes (Priority: P1)

Data models currently in `lib/backend/models/` must move to either `lib/data/` (shared schemas) or appropriate `lib/features/*/models/` (feature-specific models).

**Why this priority**: Models define the data layer. Misplaced models break the dependency direction rule (features → core/data, not reverse) and prevent feature isolation.

**Independent Test**: Can be tested by verifying each model file from `backend/models/` now exists in either `data/` or a feature's `models/` folder, and all imports resolve correctly.

**Acceptance Scenarios**:

1. **Given** `backend/models/daily_log.dart`, `period_day.dart`, `user.dart` exist, **When** restructure completes, **Then** these files exist in `data/` or `features/dashboard/models/` or `features/calendar/models/`.
2. **Given** `backend/models/onboard_item.dart` exists, **When** restructure completes, **Then** it resides in a feature's `models/` folder (likely a new onboarding feature or dashboard).

---

### User Story 3 - Relocate Services to Repositories or Core Utilities (Priority: P1)

Services in `lib/backend/services/` (`auth_service.dart`, `database_service.dart`, `notification_service.dart`) must move to `lib/data/repositories/` (for data access) or `lib/core/utils/` / feature ViewModels (for app services).

**Why this priority**: Services contain business logic and data access. Per MVVM, data access belongs in repositories; app services belong in core or ViewModels.

**Independent Test**: Can be tested by verifying each service has a new home and all imports resolve.

**Acceptance Scenarios**:

1. **Given** `database_service.dart` provides data access, **When** restructure completes, **Then** its logic resides in `data/repositories/` implementations.
2. **Given** `auth_service.dart` handles authentication, **When** restructure completes, **Then** it resides in `data/repositories/` or a feature's ViewModel.
3. **Given** `notification_service.dart` is an app-level service, **When** restructure completes, **Then** it resides in `core/utils/` or a feature ViewModel.

---

### User Story 4 - Relocate ViewModels to Feature Folders (Priority: P1)

ViewModels in `lib/backend/viewModels/` (`daily_monitor_view_model.dart`, `health_logs_view_model.dart`) must move to their respective feature's `viewModels/` folder.

**Why this priority**: ViewModels are feature-specific. Per MVVM, each feature owns its ViewModels. The current location breaks feature isolation.

**Independent Test**: Can be tested by verifying each ViewModel exists in `features/dashboard/viewModels/` or `features/calendar/viewModels/` (or a new feature folder).

**Acceptance Scenarios**:

1. **Given** `health_logs_view_model.dart` relates to health logging, **When** restructure completes, **Then** it exists in `features/dashboard/viewModels/` (since dashboard shows health logs).
2. **Given** `daily_monitor_view_model.dart` relates to daily monitoring, **When** restructure completes, **Then** it exists in `features/dashboard/viewModels/` or a new feature folder.

---

### User Story 5 - Relocate Firebase Options to Core Network (Priority: P2)

`lib/backend/firebase_options.dart` must move to `lib/core/network/` or similar constitutional location. **Firebase platform-specific credentials (API keys, app IDs, project IDs, auth domains, storage buckets, measurement IDs) must be externalized to `config.json` with platform-specific structure**, loaded at runtime via a config service, rather than hardcoded in the Dart source file.

**Why this priority**: Firebase configuration is infrastructure/network setup, belonging in `core/network/` per the architecture document. Externalizing credentials to `config.json` keeps secrets out of source control, enables environment-specific configs (dev/staging/prod), and aligns with the existing Supabase config pattern in `config.json`.

**Independent Test**: Can be tested by verifying the file exists in `core/network/`, `config.json` contains platform-specific Firebase config sections, a config service loads them at runtime, and `main.dart` initializes Firebase using the loaded config.

**Acceptance Scenarios**:

1. **Given** `firebase_options.dart` is in `backend/`, **When** restructure completes, **Then** it exists in `core/network/firebase_options.dart`.
2. **Given** the restructure, **When** `main.dart` imports Firebase options, **Then** it imports from `package:period_tracker/core/network/firebase_options.dart`.
3. **Given** the restructure, **When** inspecting `config.json`, **Then** it contains `firebase` object with `web`, `android`, `ios`, `macos`, `windows` platform configs (apiKey, appId, messagingSenderId, projectId, authDomain, storageBucket, measurementId, iosBundleId as applicable).
4. **Given** the restructure, **When** the app initializes Firebase, **Then** it uses credentials loaded from `config.json` via a config service, not hardcoded constants.

---

### User Story 6 - Verify All Imports Resolve and App Builds (Priority: P1)

After relocation, the entire application must compile and run without errors.

**Why this priority**: A restructure that breaks the build delivers zero value and blocks all development.

**Independent Test**: Run `flutter analyze` and `flutter build` — both must pass.

**Acceptance Scenarios**:

1. **Given** all files relocated, **When** running `flutter analyze`, **Then** zero errors reported.
2. **Given** all files relocated, **When** running `flutter build apk` (or platform equivalent), **Then** build succeeds.

---

### Edge Cases

- What happens to `backend/firebase_options.dart` if multiple platforms have different configs? → Keep platform-specific files in `core/network/` with clear naming.
- How does system handle imports that reference the old `backend/` paths during transition? → Use a staged migration: add new imports, verify, then remove old.
- What if a model is used by multiple features? → Place in `data/` (shared) or create a shared feature; document the decision.
- How to handle `notification_service.dart` which is initialized in `main.dart` with a ViewModel reference? → Move to `core/utils/` and accept ViewModel as parameter, or keep in dashboard feature.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST eliminate the `lib/backend/` directory entirely.
- **FR-002**: System MUST relocate all files from `lib/backend/models/` to `lib/data/` (shared schemas) or appropriate `lib/features/*/models/` (feature-specific models).
- **FR-003**: System MUST relocate all files from `lib/backend/services/` to `lib/data/repositories/` (data access) or `lib/core/utils/` / feature ViewModels (app services).
- **FR-004**: System MUST relocate all files from `lib/backend/viewModels/` to appropriate `lib/features/*/viewModels/`.
- **FR-005**: System MUST relocate `lib/backend/firebase_options.dart` to `lib/core/network/`.
- **FR-006**: System MUST update all import statements across the codebase to reflect new file locations.
- **FR-007**: System MUST ensure `flutter analyze` passes with zero errors after restructure.
- **FR-008**: System MUST ensure `flutter build` succeeds for target platforms after restructure.
- **FR-009**: System MUST preserve all existing functionality — no behavioral changes, only structural.
- **FR-010**: System MUST maintain barrel exports (`core.dart`, `data.dart`, `features.dart`, `<feature>.dart`) for all affected modules.
- **FR-011**: System MUST externalize Firebase platform-specific credentials (apiKey, appId, messagingSenderId, projectId, authDomain, storageBucket, measurementId, iosBundleId) to `config.json` with platform-specific structure (web, android, ios, macos, windows).
- **FR-012**: System MUST implement a config service in `core/network/` or `core/utils/` to load Firebase configuration from `config.json` at runtime.
- **FR-013**: System MUST initialize Firebase in `main.dart` using credentials from the config service, not hardcoded constants.
- **FR-014**: System MUST NOT commit `config.json` with real credentials to source control — `config.json` MUST be in `.gitignore`.
- **FR-015**: System MUST provide a `config.json.example` template file committed to source control with placeholder values for all required Firebase and Supabase config fields.
- **FR-016**: System MUST document the config setup process (copy `config.json.example` to `config.json`, fill in values) in README or developer onboarding docs.

### Key Entities

- **Backend Models**: `DailyLog`, `PeriodDay`, `User`, `OnboardItem` — data structures currently in `backend/models/`
- **Backend Services**: `AuthService`, `DatabaseService`, `NotificationService` — business logic currently in `backend/services/`
- **Backend ViewModels**: `DailyMonitorViewModel`, `HealthLogsViewModel` — presentation logic currently in `backend/viewModels/`
- **Firebase Options**: Platform-specific Firebase configuration currently in `backend/firebase_options.dart` — to be relocated to `core/network/firebase_options.dart` with credentials externalized to `config.json`
- **Firebase Config**: Platform-specific credential set (apiKey, appId, messagingSenderId, projectId, authDomain, storageBucket, measurementId, iosBundleId) stored in `config.json` under `firebase.{web,android,ios,macos,windows}`
- **Config Service**: Runtime configuration loader in `core/network/` or `core/utils/` that reads `config.json` and provides typed Firebase options for platform initialization

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `lib/backend/` directory does not exist after migration.
- **SC-002**: 100% of files formerly in `lib/backend/` have a new location in constitutional folders.
- **SC-003**: `flutter analyze` reports zero errors and zero warnings related to import resolution.
- **SC-004**: `flutter build` completes successfully for Android and iOS targets.
- **SC-005**: All existing features (dashboard, calendar) function identically before and after restructure (verified by manual smoke test).
- **SC-006**: No import statements reference `package:period_tracker/backend/` anywhere in the codebase.
- **SC-007**: Barrel exports (`core.dart`, `data.dart`, `features.dart`, `dashboard.dart`, `calendar.dart`) export all public APIs correctly.
- **SC-008**: `config.json` contains `firebase` object with platform-specific config for web, android, ios, macos, windows (all credential fields populated from current `firebase_options.dart`).
- **SC-009**: Firebase initialization in `main.dart` uses config service to load credentials from `config.json` — no hardcoded Firebase credentials remain in any `.dart` file.
- **SC-010**: Config service loads and validates Firebase config at startup; app fails fast with clear error if `config.json` is missing or malformed.
- **SC-011**: `config.json` is listed in `.gitignore` and NOT committed to source control (verified by `git check-ignore config.json`).
- **SC-012**: `config.json.example` exists in repo root with placeholder values for all Firebase platforms (web, android, ios, macos, windows) and Supabase (url, anonKey).
- **SC-013**: Developer onboarding docs include steps to create `config.json` from template and populate with project-specific credentials.

## Clarifications

### Session 2026-10-22

- Q: Should the Firebase platform-specific credentials (API keys, app IDs, project IDs, etc.) currently hardcoded in `lib/core/network/firebase_options.dart` be migrated to `config.json` (or another external configuration mechanism) instead of remaining in the Dart source file? → A: Migrate to config.json with platform-specific structure
- Q: Should `config.json` (containing real Firebase credentials) be committed to source control, or should it be added to `.gitignore` with a `config.json.example` template committed instead? → A: Gitignore config.json, commit config.json.example template with placeholder values

## Assumptions

- The existing `lib/core/`, `lib/data/`, `lib/features/dashboard/`, and `lib/features/calendar/` folders already comply with the MVVM structure and will not be restructured (only added to).
- `DailyLog`, `PeriodDay`, `User` are shared data schemas → belong in `lib/data/` or `lib/features/dashboard/models/` and `lib/features/calendar/models/`.
- `OnboardItem` is onboarding-specific → belongs in a feature's models (dashboard or new onboarding feature).
- `DatabaseService` logic maps to repository implementations in `lib/data/repositories/`.
- `AuthService` logic maps to repository or ViewModel in dashboard feature.
- `NotificationService` is an app-level utility → belongs in `lib/core/utils/notification_service.dart`.
- `HealthLogsViewModel` and `DailyMonitorViewModel` are dashboard-specific → belong in `lib/features/dashboard/viewModels/`.
- The `main.dart` entry point will be updated to import from new locations but otherwise unchanged.
- No new features are added — this is a pure structural migration.
- The team uses `flutter analyze` and `flutter build` as the primary validation gates.