import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/screens/achievements_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/practice/learning_screen.dart';
import '../../features/hiragana/hiragana_screen.dart';
import '../../features/katakana/katakana_screen.dart';
import '../../features/kanji/kanji_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/review/screens/review_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const DashboardScreen(),
    ),
    GoRoute(
      path: '/hiragana',
      builder: (BuildContext context, GoRouterState state) =>
          const HiraganaScreen(),
    ),
    GoRoute(
      path: '/practice/:lessonNumber',
      builder: (BuildContext context, GoRouterState state) {
        final int lessonNumber =
            int.tryParse(state.pathParameters['lessonNumber'] ?? '') ?? 1;
        final bool isReviewMode = state.uri.queryParameters['mode'] == 'review';
        final String contentId =
            state.uri.queryParameters['content'] ?? 'hiragana';
        final String? startCharacterId = state.uri.queryParameters['char'];
        return LearningScreen(
          lessonNumber: lessonNumber,
          isReviewMode: isReviewMode,
          contentId: contentId,
          startCharacterId: startCharacterId,
        );
      },
    ),
    GoRoute(
      path: '/review',
      builder: (BuildContext context, GoRouterState state) =>
          const ReviewScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (BuildContext context, GoRouterState state) =>
          const AchievementsScreen(),
    ),
    GoRoute(
      path: '/katakana',
      builder: (BuildContext context, GoRouterState state) =>
          const KatakanaScreen(),
    ),
    GoRoute(
      path: '/kanji',
      builder: (BuildContext context, GoRouterState state) =>
          const KanjiScreen(),
    ),
    GoRoute(
      path: '/progress',
      builder: (BuildContext context, GoRouterState state) =>
          const ProgressScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (BuildContext context, GoRouterState state) =>
          const SearchScreen(),
    ),
  ],
);
