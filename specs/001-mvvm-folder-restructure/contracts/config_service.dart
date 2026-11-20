// Config Service Contract
// Location: lib/core/network/config_service.dart

import 'package:firebase_core/firebase_core.dart';

abstract class ConfigServiceContract {
  /// Whether configuration has been successfully loaded
  bool get isLoaded;

  /// Loads configuration from assets/config.json
  /// Throws [ConfigError] if file missing, malformed, or incomplete
  Future<void> load();

  /// Returns FirebaseOptions for the current platform
  /// Must be called after [load()] completes successfully
  /// Throws [StateError] if not loaded or platform unsupported
  FirebaseOptions getFirebaseOptions();

  /// Returns Supabase configuration
  /// Must be called after [load()] completes successfully
  SupabaseConfig getSupabaseConfig();

  /// Returns FirebaseConfig for a specific platform
  /// Returns null if platform not configured
  FirebaseConfig? getFirebaseConfig(String platform);
}

/// Firebase configuration for a single platform
class FirebaseConfig {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;
  final String storageBucket;
  final String? measurementId;
  final String? iosBundleId;

  const FirebaseConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
    required this.storageBucket,
    this.measurementId,
    this.iosBundleId,
  });
}

/// Supabase configuration
class SupabaseConfig {
  final String url;
  final String anonKey;

  const SupabaseConfig({
    required this.url,
    required this.anonKey,
  });
}

/// Configuration errors
sealed class ConfigError implements Exception {
  const ConfigError();

  factory ConfigError.missingFile() = _MissingFile;
  factory ConfigError.malformedJson(String details) = _MalformedJson;
  factory ConfigError.missingRequiredField(String field, String platform) = _MissingRequiredField;
  factory ConfigError.unsupportedPlatform(String platform) = _UnsupportedPlatform;
}

class _MissingFile extends ConfigError {
  @override String toString() => 'config.json not found in assets. Copy config.json.example to config.json and add to pubspec.yaml assets.';
}

class _MalformedJson extends ConfigError {
  final String details;
  _MalformedJson(this.details);
  @override String toString() => 'config.json contains invalid JSON: $details';
}

class _MissingRequiredField extends ConfigError {
  final String field;
  final String platform;
  _MissingRequiredField(this.field, this.platform);
  @override String toString() => 'config.json missing required field "$field" for platform "$platform"';
}

class _UnsupportedPlatform extends ConfigError {
  final String platform;
  _UnsupportedPlatform(this.platform);
  @override String toString() => 'Platform "$platform" not supported or not configured in config.json';
}