# Research: MVVM Folder Restructure

**Date**: 2026-10-23  
**Feature**: 001-mvvm-folder-restructure

---

## 1. Firebase Configuration Externalization Pattern

### Decision
Use a runtime config service that loads `config.json` from assets at app startup, builds platform-specific `FirebaseOptions` objects, and initializes Firebase via `Firebase.initializeApp(options: configService.getFirebaseOptions())`.

### Rationale
- Keeps secrets out of source control (config.json gitignored)
- Aligns with existing Supabase config pattern in `config.json`
- Enables environment-specific configs (dev/staging/prod) via different config.json files
- FlutterFire CLI generates `firebase_options.dart` with hardcoded values; we replace with dynamic loading
- `config.json` loaded from assets bundle (included in `pubspec.yaml` assets)

### Alternatives Considered
| Approach | Pros | Cons |
|----------|------|------|
| **Runtime config.json (chosen)** | Secure, flexible, matches Supabase pattern | Requires asset loading, startup async |
| `--dart-define` build-time injection | No runtime config file, very secure | Requires CI/CD pipeline changes, harder local dev |
| Keep hardcoded in firebase_options.dart | Simplest, standard FlutterFire | Secrets in git, no env-specific configs |
| Separate dart files per env (firebase_options_dev.dart) | Type-safe, no runtime parsing | Still commits secrets, more files to maintain |

---

## 2. Config Service Implementation

### Decision
Create `lib/core/network/config_service.dart` with:
- Singleton pattern with `ConfigService.instance`
- `Future<void> load()` — loads `config.json` from assets, parses JSON
- `FirebaseOptions getFirebaseOptions()` — returns platform-specific FirebaseOptions built from loaded config
- `SupabaseConfig getSupabaseConfig()` — returns Supabase URL/anonKey
- Validation: throws descriptive error if config.json missing, malformed, or required fields absent

### Rationale
- Centralizes config loading logic in core/network per architecture
- Single source of truth for all external service configs
- Fail-fast at startup with clear error messages
- Testable via mocking ConfigService

### Config.json Structure
```json
{
  "firebase": {
    "web": {
      "apiKey": "AIzaSy...",
      "appId": "1:178689790799:web:...",
      "messagingSenderId": "178689790799",
      "projectId": "period-tracker-02b22",
      "authDomain": "period-tracker-02b22.firebaseapp.com",
      "storageBucket": "period-tracker-02b22.firebasestorage.app",
      "measurementId": "G-..."
    },
    "android": {
      "apiKey": "AIzaSy...",
      "appId": "1:178689790799:android:...",
      "messagingSenderId": "178689790799",
      "projectId": "period-tracker-02b22",
      "storageBucket": "period-tracker-02b22.firebasestorage.app"
    },
    "ios": {
      "apiKey": "AIzaSy...",
      "appId": "1:178689790799:ios:...",
      "messagingSenderId": "178689790799",
      "projectId": "period-tracker-02b22",
      "storageBucket": "period-tracker-02b22.firebasestorage.app",
      "iosBundleId": "com.example.periodTracker"
    },
    "macos": {
      "apiKey": "AIzaSy...",
      "appId": "1:178689790799:ios:...",
      "messagingSenderId": "178689790799",
      "projectId": "period-tracker-02b22",
      "storageBucket": "period-tracker-02b22.firebasestorage.app",
      "iosBundleId": "com.example.periodTracker"
    },
    "windows": {
      "apiKey": "AIzaSy...",
      "appId": "1:178689790799:web:...",
      "messagingSenderId": "178689790799",
      "projectId": "period-tracker-02b22",
      "authDomain": "period-tracker-02b22.firebaseapp.com",
      "storageBucket": "period-tracker-02b22.firebasestorage.app",
      "measurementId": "G-..."
    }
  },
  "supabase": {
    "url": "https://...supabase.co",
    "anonKey": "eyJ..."
  }
}
```

---

## 3. Migration Strategy for firebase_options.dart

### Decision
1. Keep existing `lib/core/network/firebase_options.dart` as the generated FlutterFire file (for reference)
2. Create new `lib/core/network/firebase_options_builder.dart` that builds `FirebaseOptions` from `ConfigService`
3. Update `main.dart` to:
   - Initialize `ConfigService` first
   - Call `Firebase.initializeApp(options: ConfigService.instance.getFirebaseOptions())`
4. Remove hardcoded constants from `firebase_options.dart` (or delete it entirely)

### Rationale
- Preserves FlutterFire CLI compatibility (can re-run `flutterfire configure` if needed)
- Clean separation: generated file vs runtime builder
- Minimal changes to `main.dart` initialization flow

---

## 4. config.json.example Template

### Decision
Commit `config.json.example` to repo root with all fields as descriptive placeholders:
```json
{
  "firebase": {
    "web": { "apiKey": "YOUR_WEB_API_KEY", "appId": "YOUR_WEB_APP_ID", ... },
    "android": { "apiKey": "YOUR_ANDROID_API_KEY", ... },
    "ios": { "apiKey": "YOUR_IOS_API_KEY", "iosBundleId": "YOUR_IOS_BUNDLE_ID", ... },
    "macos": { "apiKey": "YOUR_MACOS_API_KEY", "iosBundleId": "YOUR_MACOS_BUNDLE_ID", ... },
    "windows": { "apiKey": "YOUR_WINDOWS_API_KEY", ... }
  },
  "supabase": { "url": "YOUR_SUPABASE_URL", "anonKey": "YOUR_SUPABASE_ANON_KEY" }
}
```

### Rationale
- Clear documentation of required fields
- Easy copy-paste for new developers
- CI/CD can use this as template for secret injection

---

## 5. Gitignore Pattern

### Decision
Add to `.gitignore`:
```
# Config files with secrets
lib/core/config.json
config.json
```

But keep `config.json.example` tracked.

### Rationale
- Prevents accidental commit of real credentials
- Standard Flutter/Dart practice

---

## 6. Asset Loading in pubspec.yaml

### Decision
Add to `pubspec.yaml`:
```yaml
flutter:
  assets:
    - config.json
```

### Rationale
- Makes config.json available via `rootBundle.loadString('config.json')`
- Required for runtime loading

---

## 7. Testing Strategy for Config Service

### Decision
- Unit test `ConfigService` with mock asset bundle (using `rootBundle` override or wrapper)
- Test: valid config loads correctly, missing config throws, malformed JSON throws, missing required fields throws
- Integration test: app initializes Firebase successfully with test config

### Rationale
- TDD compliance (Constitution Principle V)
- Ensures fail-fast behavior works
- Validates platform-specific FirebaseOptions construction

---

## 8. Platform-Specific Firebase Config Notes

### Key Findings
- **Web**: Requires `authDomain`, `measurementId` (optional but recommended for Analytics)
- **Android**: No `authDomain`, no `measurementId`; uses `google-services.json` for some services but `FirebaseOptions` works for core
- **iOS/macOS**: Requires `iosBundleId`; uses `GoogleService-Info.plist` but `FirebaseOptions` works
- **Windows**: Same fields as web (uses web Firebase config)
- **Linux**: Not configured in current firebase_options.dart (throws UnsupportedError)

### Action
Support web, android, ios, macos, windows. Document linux as unsupported (matches current behavior).

---

## Summary of Decisions

| Topic | Decision |
|-------|----------|
| Config externalization | Runtime config.json via asset bundle |
| Config service location | `lib/core/network/config_service.dart` |
| Firebase init | `Firebase.initializeApp(options: ConfigService.instance.getFirebaseOptions())` |
| config.json in git | Gitignored; `config.json.example` committed |
| Asset loading | Added to `pubspec.yaml` flutter.assets |
| Testing | Unit + integration tests for ConfigService |
| Platforms supported | Web, Android, iOS, macOS, Windows |