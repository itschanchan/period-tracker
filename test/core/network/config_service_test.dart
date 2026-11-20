import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:period_tracker/core/network/config_service.dart';

class _TestAssetBundle extends AssetBundle {
  final Map<String, String> _assets = {};

  void setAsset(String key, String value) {
    _assets[key] = value;
  }

  @override
  Future<ByteData> load(String key) async {
    final string = _assets[key];
    if (string == null) {
      throw FlutterError('Asset not found: $key');
    }
    final bytes = Uint8List.fromList(string.codeUnits);
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final string = _assets[key];
    if (string == null) {
      throw FlutterError('Asset not found: $key');
    }
    return string;
  }

  Future<List<int>> loadBinary(String key) async {
    final string = _assets[key];
    if (string == null) {
      throw FlutterError('Asset not found: $key');
    }
    return string.codeUnits;
  }

  Future<ImageProvider> loadImage(String key, {double? scale}) async {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const validConfigJson = '''
{
  "firebase": {
    "web": {
      "apiKey": "WEB_API_KEY",
      "appId": "WEB_APP_ID",
      "messagingSenderId": "123456789",
      "projectId": "test-project",
      "authDomain": "test-project.firebaseapp.com",
      "storageBucket": "test-project.appspot.com",
      "measurementId": "G-MEASUREMENT_ID"
    },
    "android": {
      "apiKey": "ANDROID_API_KEY",
      "appId": "ANDROID_APP_ID",
      "messagingSenderId": "123456789",
      "projectId": "test-project",
      "storageBucket": "test-project.appspot.com"
    },
    "ios": {
      "apiKey": "IOS_API_KEY",
      "appId": "IOS_APP_ID",
      "messagingSenderId": "123456789",
      "projectId": "test-project",
      "storageBucket": "test-project.appspot.com",
      "iosBundleId": "com.example.test"
    },
    "macos": {
      "apiKey": "MACOS_API_KEY",
      "appId": "MACOS_APP_ID",
      "messagingSenderId": "123456789",
      "projectId": "test-project",
      "storageBucket": "test-project.appspot.com",
      "iosBundleId": "com.example.test"
    },
    "windows": {
      "apiKey": "WINDOWS_API_KEY",
      "appId": "WINDOWS_APP_ID",
      "messagingSenderId": "123456789",
      "projectId": "test-project",
      "authDomain": "test-project.firebaseapp.com",
      "storageBucket": "test-project.appspot.com",
      "measurementId": "G-MEASUREMENT_ID"
    }
  },
  "supabase": {
    "url": "https://test.supabase.co",
    "anonKey": "ANON_KEY"
  }
}
''';

  late _TestAssetBundle testAssetBundle;

  setUp(() {
    ConfigService.instance.reset();
    testAssetBundle = _TestAssetBundle();
  });

  void loadConfig(String configJson) {
    testAssetBundle.setAsset('config.json', configJson);
  }

  Future<void> loadService() async {
    await ConfigService.instance.load(assetBundle: testAssetBundle);
  }

  group('ConfigService.load()', () {
    test('loads valid config correctly', () async {
      loadConfig(validConfigJson);

      await loadService();

      expect(ConfigService.instance.isLoaded, isTrue);
      expect(ConfigService.instance.getFirebaseConfig('web'), isNotNull);
      expect(ConfigService.instance.getFirebaseConfig('android'), isNotNull);
      expect(ConfigService.instance.getFirebaseConfig('ios'), isNotNull);
      expect(ConfigService.instance.getFirebaseConfig('macos'), isNotNull);
      expect(ConfigService.instance.getFirebaseConfig('windows'), isNotNull);
      expect(ConfigService.instance.getSupabaseConfig().url, equals('https://test.supabase.co'));
      expect(ConfigService.instance.getSupabaseConfig().anonKey, equals('ANON_KEY'));
    });

    test('throws ConfigError.missingFile when config.json not found', () async {
      // Don't load any config, so it will throw

      await expectLater(
        loadService(),
        throwsA(isA<ConfigError>().having((e) => e.toString(), 'message', contains('config.json not found in assets'))),
      );
    });

    test('throws ConfigError.malformedJson when JSON is invalid', () async {
      loadConfig('{ invalid json }');

      await expectLater(
        loadService(),
        throwsA(isA<ConfigError>().having((e) => e.toString(), 'message', contains('invalid JSON'))),
      );
    });

    test('throws ConfigError.missingRequiredField when firebase object missing', () async {
      const configWithoutFirebase = '''
{
  "supabase": {
    "url": "https://test.supabase.co",
    "anonKey": "ANON_KEY"
  }
}
''';
      loadConfig(configWithoutFirebase);

      await expectLater(
        loadService(),
        throwsA(isA<ConfigError>().having((e) => e.toString(), 'message', contains('missing required field "firebase"'))),
      );
    });

    test('throws ConfigError.missingRequiredField when platform missing apiKey', () async {
      const configMissingApiKey = '''
{
  "firebase": {
    "web": {
      "appId": "WEB_APP_ID",
      "messagingSenderId": "123456789",
      "projectId": "test-project",
      "authDomain": "test-project.firebaseapp.com",
      "storageBucket": "test-project.appspot.com",
      "measurementId": "G-MEASUREMENT_ID"
    }
  },
  "supabase": {
    "url": "https://test.supabase.co",
    "anonKey": "ANON_KEY"
  }
}
''';
      loadConfig(configMissingApiKey);

      await expectLater(
        loadService(),
        throwsA(isA<ConfigError>().having((e) => e.toString(), 'message', contains('missing required field "apiKey" for platform "web"'))),
      );
    });

    test('throws ConfigError.missingRequiredField when web missing authDomain', () async {
      const configMissingAuthDomain = '''
{
  "firebase": {
    "web": {
      "apiKey": "WEB_API_KEY",
      "appId": "WEB_APP_ID",
      "messagingSenderId": "123456789",
      "projectId": "test-project",
      "storageBucket": "test-project.appspot.com",
      "measurementId": "G-MEASUREMENT_ID"
    }
  },
  "supabase": {
    "url": "https://test.supabase.co",
    "anonKey": "ANON_KEY"
  }
}
''';
      loadConfig(configMissingAuthDomain);

      await expectLater(
        loadService(),
        throwsA(isA<ConfigError>().having((e) => e.toString(), 'message', contains('missing required field "authDomain" for platform "web"'))),
      );
    });

    test('throws ConfigError.missingRequiredField when ios missing iosBundleId', () async {
      const configMissingBundleId = '''
{
  "firebase": {
    "ios": {
      "apiKey": "IOS_API_KEY",
      "appId": "IOS_APP_ID",
      "messagingSenderId": "123456789",
      "projectId": "test-project",
      "storageBucket": "test-project.appspot.com"
    }
  },
  "supabase": {
    "url": "https://test.supabase.co",
    "anonKey": "ANON_KEY"
  }
}
''';
      loadConfig(configMissingBundleId);

      await expectLater(
        loadService(),
        throwsA(isA<ConfigError>().having((e) => e.toString(), 'message', contains('missing required field "iosBundleId" for platform "ios"'))),
      );
    });
  });

  group('ConfigService.getFirebaseOptions()', () {
    test('throws StateError when not loaded', () {
      expect(
        () => ConfigService.instance.getFirebaseOptions(),
        throwsA(isA<StateError>().having((e) => e.toString(), 'message', contains('ConfigService not loaded'))),
      );
    });

    test('returns FirebaseOptions for current platform after load', () async {
      loadConfig(validConfigJson);
      await loadService();

      final options = ConfigService.instance.getFirebaseOptions();

      expect(options, isA<FirebaseOptions>());
      expect(options.projectId, equals('test-project'));
      expect(options.messagingSenderId, equals('123456789'));
    });
  });

  group('ConfigService.getSupabaseConfig()', () {
    test('throws StateError when not loaded', () {
      expect(
        () => ConfigService.instance.getSupabaseConfig(),
        throwsA(isA<StateError>().having((e) => e.toString(), 'message', contains('ConfigService not loaded'))),
      );
    });

    test('returns SupabaseConfig after load', () async {
      loadConfig(validConfigJson);
      await loadService();

      final config = ConfigService.instance.getSupabaseConfig();
      expect(config.url, equals('https://test.supabase.co'));
      expect(config.anonKey, equals('ANON_KEY'));
    });
  });

  group('ConfigService.getFirebaseConfig()', () {
    test('returns null when not loaded', () {
      expect(ConfigService.instance.getFirebaseConfig('web'), isNull);
    });

    test('returns FirebaseConfig for platform after load', () async {
      loadConfig(validConfigJson);
      await loadService();

      final webConfig = ConfigService.instance.getFirebaseConfig('web');
      expect(webConfig, isNotNull);
      expect(webConfig!.apiKey, equals('WEB_API_KEY'));
      expect(webConfig.authDomain, equals('test-project.firebaseapp.com'));
      expect(webConfig.measurementId, equals('G-MEASUREMENT_ID'));

      final androidConfig = ConfigService.instance.getFirebaseConfig('android');
      expect(androidConfig, isNotNull);
      expect(androidConfig!.apiKey, equals('ANDROID_API_KEY'));
      expect(androidConfig.authDomain, isNull);
      expect(androidConfig.measurementId, isNull);

      final iosConfig = ConfigService.instance.getFirebaseConfig('ios');
      expect(iosConfig, isNotNull);
      expect(iosConfig!.iosBundleId, equals('com.example.test'));
    });

    test('returns null for unsupported platform', () async {
      loadConfig(validConfigJson);
      await loadService();

      expect(ConfigService.instance.getFirebaseConfig('linux'), isNull);
      expect(ConfigService.instance.getFirebaseConfig('unknown'), isNull);
    });
  });
}