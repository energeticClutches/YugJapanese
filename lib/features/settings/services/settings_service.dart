import 'package:hive/hive.dart';

import '../../achievements/repositories/hive_achievement_repository.dart';
import '../../progress/repositories/hive_progress_repository.dart';
import '../../review/repositories/hive_review_repository.dart';
import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';

/// Supported values for [AppSettings.language]. New locales should be added
/// here so [SettingsService] can keep validating stored/incoming values.
const List<String> supportedLanguages = <String>['en', 'ja'];

/// Updates, validates, and resets [AppSettings], and clears the local Hive
/// boxes owned by other features when the user resets all progress.
class SettingsService {
  const SettingsService(this._repository);

  final SettingsRepository _repository;

  Future<AppSettings> loadSettings() => _repository.loadSettings();

  Future<AppSettings> updateSettings(AppSettings settings) async {
    final AppSettings validated = _validate(settings);
    await _repository.saveSettings(validated);
    return validated;
  }

  Future<AppSettings> resetSettings() async {
    await _repository.resetToDefaults();
    return AppSettings.defaults;
  }

  /// Clears all locally persisted learning progress, review schedules, and
  /// achievement unlocks. Does not touch [AppSettings] itself.
  Future<void> resetAllProgress() async {
    await Future.wait(<Future<void>>[
      _clearBox(HiveProgressRepository.boxName),
      _clearBox(HiveReviewRepository.boxName),
      _clearBox(HiveAchievementRepository.boxName),
    ]);
  }

  Future<void> _clearBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box<dynamic>(boxName).clear();
    }
  }

  AppSettings _validate(AppSettings settings) {
    if (supportedLanguages.contains(settings.language)) {
      return settings;
    }
    return settings.copyWith(language: AppSettings.defaults.language);
  }
}
