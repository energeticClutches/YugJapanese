import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import 'settings_service.dart';

/// Holds the current [AppSettings] in memory and notifies listeners
/// immediately on update, so UI (like the app's `ThemeMode`) reacts without
/// waiting on a fresh Hive read.
class SettingsController extends ChangeNotifier {
  SettingsController(this._service) {
    _load();
  }

  final SettingsService _service;
  AppSettings _settings = AppSettings.defaults;
  bool _isReady = false;

  AppSettings get settings => _settings;
  bool get isReady => _isReady;

  Future<void> _load() async {
    _settings = await _service.loadSettings();
    _isReady = true;
    notifyListeners();
  }

  Future<void> update(AppSettings settings) async {
    _settings = await _service.updateSettings(settings);
    notifyListeners();
  }

  Future<void> resetSettings() async {
    _settings = await _service.resetSettings();
    notifyListeners();
  }

  Future<void> resetAllProgress() => _service.resetAllProgress();
}
