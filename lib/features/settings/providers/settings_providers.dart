import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../repositories/hive_settings_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/coming_soon_gate.dart';
import '../services/settings_controller.dart';
import '../services/settings_service.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (Ref ref) => const HiveSettingsRepository(),
);

final settingsServiceProvider = Provider<SettingsService>(
  (Ref ref) => SettingsService(ref.watch(settingsRepositoryProvider)),
);

final currentSettingsProvider = ChangeNotifierProvider<SettingsController>(
  (Ref ref) => SettingsController(ref.watch(settingsServiceProvider)),
);

/// App-lifetime singleton — one gate instance shared by every screen that
/// shows "not available yet" notices, so the cooldown is meaningful
/// regardless of navigation in between.
final comingSoonGateProvider = Provider<ComingSoonGate>(
  (Ref ref) => ComingSoonGate(),
);

final storageUsageProvider = FutureProvider<int>(
  (Ref ref) async {
    ref.watch(currentSettingsProvider);
    return ref.watch(settingsServiceProvider).getStorageUsageBytes();
  },
);
