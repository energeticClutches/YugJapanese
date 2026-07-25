import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/search/repositories/hive_favorites_repository.dart';
import 'features/search/repositories/hive_search_history_repository.dart';
import 'features/settings/models/app_settings.dart';
import 'features/settings/providers/settings_providers.dart';
import 'features/settings/repositories/hive_settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>('lesson_progress');
  await Hive.openBox<dynamic>('review_schedule');
  await Hive.openBox<dynamic>('achievement_progress');
  await Hive.openBox<dynamic>(HiveSettingsRepository.boxName);
  await Hive.openBox<dynamic>(HiveFavoritesRepository.boxName);
  await Hive.openBox<dynamic>(HiveSearchHistoryRepository.boxName);
  runApp(const JapaneseLearningApp());
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
