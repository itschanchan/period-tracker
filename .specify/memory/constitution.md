# Flutter Period Tracker Constitution

## Core Principles

### I. MVVM Architecture Compliance
All features MUST follow the Model-View-ViewModel (MVVM) architecture pattern. The separation of concerns is non-negotiable:
- **Models** (`features/*/models/`) represent the data layer and core business rules
- **ViewModels** (`features/*/viewModels/`) act as the bridge between View and Model, exposing state and commands
- **Views** (`features/*/views/`) render the UI and capture user input only

Rationale: MVVM ensures testability, maintainability, and clear separation between business logic and UI rendering.

### II. Constitutional Folder Structure
The `lib/` directory MUST strictly adhere to this structure:

```
lib/
|-- core/                    # Shared global resources
|   |-- constants/           # Application-wide constants (AppConstants)
|   |-- network/             # Supabase/Firebase configuration
|   |-- routes/              # Central route definitions (AppRoutes)
|   |-- theme/               # Global theme management (AppTheme)
|   |-- utils/               # Shared utilities (date, prefs, helpers)
|   |-- core.dart            # Core barrel export
|
|-- data/                    # Data layer - schemas & persistence
|   |-- local/               # Local data sources (Hive, SharedPreferences)
|   |-- repositories/        # Repository interfaces & implementations
|   |-- data.dart            # Data barrel export
|
|-- features/                # Feature modules (MVVM per feature)
|   |-- <feature-name>/
|   |   |-- models/          # Feature-specific data models
|   |   |-- viewModels/      # Feature-specific ViewModels
|   |   |-- views/           # Feature-specific UI
|   |   |   |-- components/  # Reusable view components
|   |   |-- <feature>.dart   # Feature barrel export
|   |-- features.dart        # Features barrel export
|
|-- main.dart                # Application entry point ONLY
```

Rationale: Enforces consistent organization, enables feature isolation, and prevents circular dependencies.

### III. No Redundant Orphan Files
No files SHALL exist outside the defined folder structure. Any business logic found in incorrect locations MUST be moved to its constitutional home:
- Shared constants → `core/constants/`
- Theme definitions → `core/theme/`
- Utility functions → `core/utils/`
- Data models/schemas → `data/` or `features/*/models/`
- Database setup → `data/local/` & `data/repositories/`
- Feature-specific logic → respective `features/*/` MVVM folders

Rationale: Prevents technical debt, ensures discoverability, and maintains architectural integrity.

### IV. Barrel Export Discipline
Every folder with multiple Dart files MUST provide a barrel export file (e.g., `core.dart`, `data.dart`, `features.dart`, `<feature>.dart`). Direct imports of nested files from outside their feature/module are PROHIBITED.

Rationale: Controls public API surface, simplifies imports, and enables refactoring without breaking consumers.

### V. Test-First Development (NON-NEGOTIABLE)
TDD is mandatory for all new features and bug fixes:
1. Write failing tests first
2. Get user approval on test cases
3. Implement to make tests pass
4. Refactor with confidence

Integration tests REQUIRED for: repository contracts, ViewModel logic, cross-feature data flows.

Rationale: Guarantees correctness, documents expected behavior, enables safe refactoring.

## Architecture Standards

### State Management
Provider pattern with `ChangeNotifier` for ViewModels. No global state outside ViewModels. UI rebuilds triggered only via `notifyListeners()`.

### Dependency Direction
`features/` → `core/` and `data/` (one-way). `core/` and `data/` MUST NOT import from `features/`.

### Error Handling
All async operations in ViewModels MUST use try-catch with user-facing error states. Never let exceptions crash the UI.

### Data Flow
View → ViewModel (commands) → Repository → Data Source → Model → ViewModel (state) → View

## Governance

This constitution supersedes all other development practices. Amendments require:
1. Documented rationale in PR description
2. Architecture review approval
3. Migration plan for existing code
4. Version bump per semantic versioning

**Compliance Review**: All PRs must verify:
- Folder structure adherence
- MVVM separation (no business logic in Views)
- Barrel exports used correctly
- Tests written for new logic

**Version**: 1.0.0 | **Ratified**: 2026-10-22 | **Last Amended**: 2026-10-22