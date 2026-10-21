import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/core.dart';

class CycleLocalDataSource {
  final SharedPreferences _prefs;
  
  CycleLocalDataSource(this._prefs);
  
  Future<void> saveCycleData(Map<String, dynamic> data) async {
    await _prefs.setString(AppConstants.prefsKeyCycleData, jsonEncode(data));
  }
  
  Map<String, dynamic>? getCycleData() {
    final data = _prefs.getString(AppConstants.prefsKeyCycleData);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }
  
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    await _prefs.setString(AppConstants.prefsKeyUserSettings, jsonEncode(settings));
  }
  
  Map<String, dynamic>? getUserSettings() {
    final data = _prefs.getString(AppConstants.prefsKeyUserSettings);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }
  
  Future<void> clearCycleData() async {
    await _prefs.remove(AppConstants.prefsKeyCycleData);
  }
  
  Future<void> clearUserSettings() async {
    await _prefs.remove(AppConstants.prefsKeyUserSettings);
  }
}