import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../achievements/repositories/hive_achievement_repository.dart';
import '../../analytics/repositories/hive_analytics_repository.dart';
import '../../progress/repositories/hive_progress_repository.dart';
import '../../quiz/repositories/hive_practice_repository.dart';
import '../../review/repositories/hive_review_repository.dart';
import '../../search/repositories/hive_favorites_repository.dart';
import '../../search/repositories/hive_search_history_repository.dart';
import '../models/app_settings.dart';
import '../repositories/hive_settings_repository.dart';
import '../repositories/settings_repository.dart';

/// Every Hive box this app opens (mirrors `main.dart`'s bootstrap list) —
/// used to compute the Diagnostics storage-usage summary.
const List<String> allHiveBoxNames = <String>[
  HiveProgressRepository.boxName,
  HiveReviewRepository.boxName,
  HiveAchievementRepository.boxName,
  HiveSettingsRepository.boxName,
  HiveFavoritesRepository.boxName,
  HiveSearchHistoryRepository.boxName,
  HivePracticeRepository.boxName,
  HiveAnalyticsRepository.boxName,
];

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

  /// Clears all locally persisted learning progress, review schedules,
  /// achievement unlocks, practice/quiz history, and analytics snapshots.
  /// Does not touch [AppSettings], favorites, or search history.
  Future<void> resetAllProgress() async {
    await Future.wait(<Future<void>>[
      _clearBox(HiveProgressRepository.boxName),
      _clearBox(HiveReviewRepository.boxName),
      _clearBox(HiveAchievementRepository.boxName),
      _clearBox(HivePracticeRepository.boxName),
      _clearBox(HiveAnalyticsRepository.boxName),
    ]);
  }

  Future<void> _clearBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box<dynamic>(boxName).clear();
    }
  }

  /// Sums the on-disk size of every Hive box file, for the Settings
  /// screen's Diagnostics section. Missing files (a box that hasn't
  /// written anything yet) contribute 0 rather than throwing.
  Future<int> getStorageUsageBytes() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    int total = 0;
    for (final String boxName in allHiveBoxNames) {
      final File file = File('${directory.path}/$boxName.hive');
      try {
        total += await file.length();
      } catch (_) {
        // Box file doesn't exist yet (never written to) — contributes 0.
      }
    }
    return total;
  }

  AppSettings _validate(AppSettings settings) {
    if (supportedLanguages.contains(settings.language)) {
      return settings;
    }
    return settings.copyWith(language: AppSettings.defaults.language);
  }
}
