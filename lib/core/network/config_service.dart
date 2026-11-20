// Config Service
// Loads configuration from assets/config.json at runtime

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle, AssetBundle;

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

  factory FirebaseConfig.fromJson(Map<String, dynamic> json) {
    return FirebaseConfig(
      apiKey: json['apiKey'] as String,
      appId: json['appId'] as String,
      messagingSenderId: json['messagingSenderId'] as String,
      projectId: json['projectId'] as String,
      authDomain: json['authDomain'] as String?,
      storageBucket: json['storageBucket'] as String,
      measurementId: json['measurementId'] as String?,
      iosBundleId: json['iosBundleId'] as String?,
    );
  }
}

/// Supabase configuration
class SupabaseConfig {
  final String url;
  final String anonKey;

  const SupabaseConfig({
    required this.url,
    required this.anonKey,
  });

  factory SupabaseConfig.fromJson(Map<String, dynamic> json) {
    return SupabaseConfig(
      url: json['url'] as String,
      anonKey: json['anonKey'] as String,
    );
  }
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

/// Runtime configuration loader
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() => _instance;

  static ConfigService get instance => _instance;

  ConfigService._internal();

  Map<String, FirebaseConfig>? _firebaseConfigs;
  SupabaseConfig? _supabaseConfig;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Loads configuration from assets/config.json
  Future<void> load({AssetBundle? assetBundle}) async {
    if (_isLoaded) return;

    final bundle = assetBundle ?? rootBundle;
    String configString;
    try {
      configString = await bundle.loadString('config.json');
    } catch (_) {
      throw ConfigError.missingFile();
    }

    Map<String, dynamic> configMap;
    try {
      configMap = jsonDecode(configString) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw ConfigError.malformedJson(e.toString());
    }

    // Parse Firebase configs
    final firebaseMap = configMap['firebase'] as Map<String, dynamic>?;
    if (firebaseMap == null) {
      throw ConfigError.missingRequiredField('firebase', 'root');
    }

    _firebaseConfigs = {};
    for (final entry in firebaseMap.entries) {
      final platform = entry.key;
      final platformConfig = entry.value as Map<String, dynamic>;

      // Validate required fields
      final requiredFields = ['apiKey', 'appId', 'messagingSenderId', 'projectId', 'storageBucket'];
      for (final field in requiredFields) {
        if (!platformConfig.containsKey(field) || platformConfig[field] == null || platformConfig[field].toString().isEmpty) {
          throw ConfigError.missingRequiredField(field, platform);
        }
      }

      // Validate platform-specific required fields
      if ((platform == 'web' || platform == 'windows') && (!platformConfig.containsKey('authDomain') || platformConfig['authDomain'] == null || platformConfig['authDomain'].toString().isEmpty)) {
        throw ConfigError.missingRequiredField('authDomain', platform);
      }
      if ((platform == 'web' || platform == 'windows') && (!platformConfig.containsKey('measurementId') || platformConfig['measurementId'] == null || platformConfig['measurementId'].toString().isEmpty)) {
        throw ConfigError.missingRequiredField('measurementId', platform);
      }
      if ((platform == 'ios' || platform == 'macos') && (!platformConfig.containsKey('iosBundleId') || platformConfig['iosBundleId'] == null || platformConfig['iosBundleId'].toString().isEmpty)) {
        throw ConfigError.missingRequiredField('iosBundleId', platform);
      }

      _firebaseConfigs![platform] = FirebaseConfig.fromJson(platformConfig);
    }

    // Parse Supabase config
    final supabaseMap = configMap['supabase'] as Map<String, dynamic>?;
    if (supabaseMap == null) {
      throw ConfigError.missingRequiredField('supabase', 'root');
    }

    if (!supabaseMap.containsKey('url') || supabaseMap['url'] == null || supabaseMap['url'].toString().isEmpty) {
      throw ConfigError.missingRequiredField('url', 'supabase');
    }
    if (!supabaseMap.containsKey('anonKey') || supabaseMap['anonKey'] == null || supabaseMap['anonKey'].toString().isEmpty) {
      throw ConfigError.missingRequiredField('anonKey', 'supabase');
    }

    _supabaseConfig = SupabaseConfig.fromJson(supabaseMap);
    _isLoaded = true;
  }

  /// Returns FirebaseOptions for the current platform
  FirebaseOptions getFirebaseOptions() {
    if (!_isLoaded) {
      throw StateError('ConfigService not loaded. Call load() first.');
    }

    String platform;
    if (kIsWeb) {
      platform = 'web';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          platform = 'android';
        case TargetPlatform.iOS:
          platform = 'ios';
        case TargetPlatform.macOS:
          platform = 'macos';
        case TargetPlatform.windows:
          platform = 'windows';
        case TargetPlatform.linux:
          throw ConfigError.unsupportedPlatform('linux');
        default:
          throw ConfigError.unsupportedPlatform(defaultTargetPlatform.toString());
      }
    }

    final config = _firebaseConfigs![platform];
    if (config == null) {
      throw ConfigError.unsupportedPlatform(platform);
    }

    return FirebaseOptions(
      apiKey: config.apiKey,
      appId: config.appId,
      messagingSenderId: config.messagingSenderId,
      projectId: config.projectId,
      authDomain: config.authDomain,
      storageBucket: config.storageBucket,
      measurementId: config.measurementId,
      iosBundleId: config.iosBundleId,
    );
  }

  /// Returns Supabase configuration
  SupabaseConfig getSupabaseConfig() {
    if (!_isLoaded) {
      throw StateError('ConfigService not loaded. Call load() first.');
    }
    return _supabaseConfig!;
  }

  /// Returns FirebaseConfig for a specific platform
  FirebaseConfig? getFirebaseConfig(String platform) {
    if (!_isLoaded) return null;
    return _firebaseConfigs?[platform];
  }

  /// Resets the service state (for testing only)
  @visibleForTesting
  void reset() {
    _isLoaded = false;
    _firebaseConfigs = null;
    _supabaseConfig = null;
  }
}