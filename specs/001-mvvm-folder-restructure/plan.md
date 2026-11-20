# Implementation Plan: MVVM Folder Restructure

**Branch**: `001-mvvm-folder-restructure` | **Date**: 2026-10-23 | **Spec**: specs/001-mvvm-folder-restructure/spec.md

**Input**: Feature specification from `/specs/001-mvvm-folder-restructure/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command; its definition describes the execution workflow.

## Summary

Restructure the Flutter Period Tracker codebase from a non-compliant `lib/backend/` folder structure to the constitutional MVVM architecture defined in `docs/mvvm_architecture.md`. This involves eliminating `lib/backend/`, relocating models to `lib/data/` or `lib/features/*/models/`, services to `lib/data/repositories/` or `lib/core/utils/`, ViewModels to `lib/features/*/viewModels/`, and Firebase configuration to `lib/core/network/` with credentials externalized to `config.json` (gitignored) via a config service.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: firebase_core, firebase_auth, cloud_firestore, firebase_messaging, supabase_flutter, provider, hive, shared_preferences

**Storage**: Firebase Firestore (cloud), Hive/SharedPreferences (local), Firebase Auth

**Testing**: flutter_test (unit/widget), integration_test (integration), mockito (mocks)

**Target Platform**: Android (API 21+), iOS (13+), Web, Windows, macOS

**Project Type**: mobile-app (Flutter)

**Performance Goals**: App startup <3s, UI 60fps, Firebase init <2s

**Constraints**: Constitutional folder structure (core/, data/, features/), MVVM separation, barrel exports, TDD mandatory, no `backend/` folder, dependency direction: features → core/data only

**Scale/Scope**: ~50 Dart files migrated, 4 features (dashboard, calendar, onboarding, settings), 5 platforms

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. MVVM Architecture Compliance | ✅ PASS | Restructure enforces MVVM per feature |
| II. Constitutional Folder Structure | ✅ PASS | Eliminates `backend/`, enforces core/data/features |
| III. No Redundant Orphan Files | ✅ PASS | All files relocated to constitutional homes |
| IV. Barrel Export Discipline | ✅ PASS | Barrel exports required for all modules (FR-010) |
| V. Test-First Development | ✅ PASS | flutter analyze/build gates (FR-007, FR-008) |
| State Management (Provider/ChangeNotifier) | ✅ PASS | ViewModels use ChangeNotifier |
| Dependency Direction (features → core/data) | ✅ PASS | Enforced by folder structure |
| Error Handling (try-catch in ViewModels) | ✅ PASS | Existing pattern preserved |
| Data Flow (View→VM→Repo→Source→Model→VM→View) | ✅ PASS | Repository pattern in data/repositories/ |

No violations — all gates pass.

## Project Structure

### Documentation (this feature)

```text
specs/001-mvvm-folder-restructure/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   ├── network/
│   │   ├── firebase_options.dart      # Platform-agnostic FirebaseOptions builder
│   │   ├── config_service.dart        # Loads config.json at runtime
│   │   └── core.dart
│   ├── routes/
│   ├── theme/
│   ├── utils/
│   └── core.dart
├── data/
│   ├── local/
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── database_repository.dart
│   │   ├── notification_repository.dart
│   │   └── repositories.dart
│   └── data.dart
├── features/
│   ├── dashboard/
│   │   ├── models/
│   │   │   ├── daily_log.dart
│   │   │   ├── period_day.dart
│   │   │   └── models.dart
│   │   ├── viewModels/
│   │   │   ├── daily_monitor_view_model.dart
│   │   │   ├── health_logs_view_model.dart
│   │   │   └── viewModels.dart
│   │   ├── views/
│   │   │   ├── components/
│   │   │   └── dashboard.dart
│   │   └── dashboard.dart
│   ├── calendar/
│   │   ├── models/
│   │   │   ├── period_day.dart
│   │   │   └── models.dart
│   │   ├── viewModels/
│   │   ├── views/
│   │   │   └── components/
│   │   └── calendar.dart
│   ├── onboarding/
│   │   ├── models/
│   │   │   └── onboard_item.dart
│   │   ├── viewModels/
│   │   ├── views/
│   │   └── onboarding.dart
│   ├── settings/
│   │   ├── models/
│   │   ├── viewModels/
│   │   ├── views/
│   │   └── settings.dart
│   └── features.dart
├── main.dart
```

**Structure Decision**: Option 3 (Mobile app structure) — Flutter project with lib/ containing core/, data/, features/ per constitutional MVVM architecture. The `lib/backend/` folder is eliminated entirely.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | N/A | N/A |
