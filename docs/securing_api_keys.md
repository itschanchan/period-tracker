# API Key Security

This documentation for standard security measures in securing API keys and other sensitive keys to be used in this project.

## Built-in Security

Flutter natively allows passing JSON or Properties file at compile time instead of adding heavy dependencies.

1. Create a `config.json` file in the root folder and include this file at `.gitignore`:

**Sample JSON code**:

```json
{
  "API_URL": "https://api.example.com",
  "APP_TITLE": "My Awesome App"
}
```

2. Read the values in your Dart code:

**Sample Dart code**:

```dart
const apiUrl = String.fromEnvironment('API_URL');
const appTitle = String.fromEnvironment('APP_TITLE');
```

3. Run or build your app by pointing the file:

**Sample Commands**:

```bash
flutter run --dart-define-from-file=config.json

# For Android
flutter build apk --dart-define-from-file=config.prod.json

# For iOS
flutter build ipa --dart-define-from-file-config.prod.json

# For Web
flutter build web --dart-define-from-file-config.prod.json
```
