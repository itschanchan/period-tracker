import 'cycle_repository.dart';
import '../local/cycle_local_data_source.dart';

class CycleRepositoryImpl implements CycleRepository {
  final CycleLocalDataSource _localDataSource;
  
  CycleRepositoryImpl(this._localDataSource);
  
  @override
  Future<void> saveCycleData(Map<String, dynamic> data) async {
    await _localDataSource.saveCycleData(data);
  }
  
  @override
  Map<String, dynamic>? getCycleData() {
    return _localDataSource.getCycleData();
  }
  
  @override
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    await _localDataSource.saveUserSettings(settings);
  }
  
  @override
  Map<String, dynamic>? getUserSettings() {
    return _localDataSource.getUserSettings();
  }
  
  @override
  Future<void> clearCycleData() async {
    await _localDataSource.clearCycleData();
  }
  
  @override
  Future<void> clearUserSettings() async {
    await _localDataSource.clearUserSettings();
  }
}