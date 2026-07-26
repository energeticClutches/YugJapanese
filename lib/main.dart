import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/repositories/hive_analytics_repository.dart';
import 'features/quiz/repositories/hive_practice_repository.dart';
import 'features/search/repositories/hive_favorites_repository.dart';
import 'features/search/repositories/hive_search_history_repository.dart';
import 'features/settings/models/app_settings.dart';
import 'features/settings/providers/settings_providers.dart';
import 'features/settings/repositories/hive_settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Future.wait(<Future<void>>[
    _openBoxSafely('lesson_progress'),
    _openBoxSafely('review_schedule'),
    _openBoxSafely('achievement_progress'),
    _openBoxSafely(HiveSettingsRepository.boxName),
    _openBoxSafely(HiveFavoritesRepository.boxName),
    _openBoxSafely(HiveSearchHistoryRepository.boxName),
    _openBoxSafely(HivePracticeRepository.boxName),
    _openBoxSafely(HiveAnalyticsRepository.boxName),
  ]);
  runApp(const JapaneseLearningApp());
}

/// Opens [boxName], recovering from a corrupted box file by deleting and
/// recreating it empty instead of letting a single bad box crash the whole
/// app at launch. All boxes are independent, so they open in parallel via
/// [Future.wait] in [main] rather than sequentially.
Future<void> _openBoxSafely(String boxName) async {
  try {
    await Hive.openBox<dynamic>(boxName);
  } catch (_) {
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox<dynamic>(boxName);
  }
}

class JapaneseLearningApp extends StatelessWidget {
  const JapaneseLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final AppThemeMode mode =
              ref.watch(currentSettingsProvider).settings.themeMode;
          return MaterialApp.router(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _toThemeMode(mode),
            routerConfig: appRouter,
            builder: (BuildContext context, Widget? child) {
              // Clamp extreme system text scaling so large accessibility
              // font settings can't break card layouts, while still
              // allowing real accessibility scaling up to 1.6x.
              return MediaQuery.withClampedTextScaling(
                minScaleFactor: 1.0,
                maxScaleFactor: 1.6,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }

  ThemeMode _toThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}
