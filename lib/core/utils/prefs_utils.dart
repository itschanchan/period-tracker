import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class PrefsUtils {
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static SharedPreferences get instance {
    if (_prefs == null) {
      throw StateError('PrefsUtils not initialized. Call PrefsUtils.init() first.');
    }
    return _prefs!;
  }
  
  static Future<bool> setBool(String key, bool value) async {
    return await instance.setBool(key, value);
  }
  
  static bool getBool(String key, {bool defaultValue = false}) {
    return instance.getBool(key) ?? defaultValue;
  }
  
  static Future<bool> setString(String key, String value) async {
    return await instance.setString(key, value);
  }
  
  static String? getString(String key) {
    return instance.getString(key);
  }
  
  static Future<bool> setInt(String key, int value) async {
    return await instance.setInt(key, value);
  }
  
  static int getInt(String key, {int defaultValue = 0}) {
    return instance.getInt(key) ?? defaultValue;
  }
  
  static Future<bool> setDouble(String key, double value) async {
    return await instance.setDouble(key, value);
  }
  
  static double getDouble(String key, {double defaultValue = 0.0}) {
    return instance.getDouble(key) ?? defaultValue;
  }
  
  static Future<bool> setStringList(String key, List<String> value) async {
    return await instance.setStringList(key, value);
  }
  
  static List<String> getStringList(String key, {List<String> defaultValue = const []}) {
    return instance.getStringList(key) ?? defaultValue;
  }
  
  static Future<bool> remove(String key) async {
    return await instance.remove(key);
  }
  
  static Future<bool> clear() async {
    return await instance.clear();
  }
  
  static bool get isFirstLaunch => getBool(AppConstants.prefsKeyFirstLaunch, defaultValue: true);
  static Future<void> setFirstLaunchComplete() async {
    await setBool(AppConstants.prefsKeyFirstLaunch, false);
  }
}