import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:japanese_learning/features/achievements/models/achievement_progress.dart';
import 'package:japanese_learning/features/achievements/models/streak_info.dart';
import 'package:japanese_learning/features/achievements/providers/achievement_providers.dart';
import 'package:japanese_learning/features/analytics/models/learning_analytics.dart';
import 'package:japanese_learning/features/analytics/providers/analytics_providers.dart';
import 'package:japanese_learning/features/dashboard/models/learning_statistics.dart';
import 'package:japanese_learning/features/dashboard/providers/dashboard_providers.dart';
import 'package:japanese_learning/features/dashboard/screens/dashboard_screen.dart';
import 'package:japanese_learning/features/progress/providers/progress_providers.dart';
import 'package:japanese_learning/features/quiz/models/practice_result.dart';
import 'package:japanese_learning/features/quiz/models/practice_statistics.dart';
import 'package:japanese_learning/features/quiz/providers/practice_providers.dart';
import 'package:japanese_learning/features/review/models/review_item.dart';
import 'package:japanese_learning/features/review/providers/review_providers.dart';

import '../fakes/fake_progress_repository.dart';

/// Every async provider `DashboardScreen` watches is overridden directly
/// with an already-resolved value. This is a deliberate choice, not the
/// original plan (repository-level fakes only): several of the real
/// `FutureProvider`s here `ref.watch()` a legacy `ChangeNotifierProvider`
/// (`practiceServiceProvider`) purely as an invalidation trigger, and that
/// combination deadlocks specifically inside `flutter_test`'s
/// `ProviderContainer` scheduling — reproducible in isolation with nothing
/// but `practiceServiceProvider` + one dependent `FutureProvider`, and not
/// related to anything this milestone changed. It is not reproducible in
/// the real app (verified working live on the Android emulator across
/// M17/M18/M19 manual testing). Overriding every async provider directly
/// keeps this test exercising what it's actually meant to check —
/// `DashboardScreen`'s own rendering — without depending on that unrelated
/// test-harness/library interaction.
void main() {
  testWidgets(
    'DashboardScreen renders the welcome header with no data, without throwing',
    (WidgetTester tester) async {
      final GoRouter router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                const DashboardScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressRepositoryProvider
                .overrideWithValue(FakeProgressRepository()),
            learningStatisticsProvider.overrideWith(
              (Ref ref) async => LearningStatistics.empty,
            ),
            dueReviewsProvider.overrideWith(
              (Ref ref) async => const <ReviewItem>[],
            ),
            streakInfoProvider.overrideWith(
              (Ref ref) async => StreakInfo.empty,
            ),
            achievementProgressListProvider.overrideWith(
              (Ref ref) async => const <AchievementProgress>[],
            ),
            practiceStatisticsProvider.overrideWith(
              (Ref ref) async => PracticeStatistics.empty,
            ),
            practiceResultsProvider.overrideWith(
              (Ref ref) async => const <PracticeResult>[],
            ),
            learningAnalyticsProvider.overrideWith(
              (Ref ref) async => LearningAnalytics.empty,
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Continue your Japanese journey.'), findsOneWidget);
      // With no progress recorded anywhere, the streak/achievement empty
      // copy should be showing rather than a crash or stuck spinner.
      expect(
        find.text('Complete lessons to earn your first achievement.'),
        findsOneWidget,
      );
    },
  );
}
