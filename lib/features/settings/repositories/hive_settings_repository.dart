import 'package:hive/hive.dart';

import '../../../core/utils/safe_parse.dart';
import '../models/app_settings.dart';
import 'settings_repository.dart';

class HiveSettingsRepository implements SettingsRepository {
  const HiveSettingsRepository();

  static const String boxName = 'app_settings';
  static const String settingsKey = 'settings';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<AppSettings> loadSettings() async {
    final value = _box.get(settingsKey);
    if (value is! Map) {
      return AppSettings.defaults;
    }
    return safeParse(value, AppSettings.fromMap) ?? AppSettings.defaults;
  }

  @override
  Future<void> saveSettings(AppSettings settings) {
    return _box.put(settingsKey, settings.toMap());
  }

  @override
  Future<void> resetToDefaults() {
    return _box.put(settingsKey, AppSettings.defaults.toMap());
  }
}
