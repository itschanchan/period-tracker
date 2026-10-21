abstract class CycleRepository {
  Future<void> saveCycleData(Map<String, dynamic> data);
  Map<String, dynamic>? getCycleData();
  Future<void> saveUserSettings(Map<String, dynamic> settings);
  Map<String, dynamic>? getUserSettings();
  Future<void> clearCycleData();
  Future<void> clearUserSettings();
}