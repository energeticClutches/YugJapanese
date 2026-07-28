import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/screens/achievements_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/practice/learning_screen.dart';
import '../../features/hiragana/hiragana_screen.dart';
import '../../features/katakana/katakana_screen.dart';
import '../../features/kanji/kanji_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/quiz/screens/practice_home_screen.dart';
import '../../features/quiz/screens/practice_results_screen.dart';
import '../../features/quiz/screens/practice_session_screen.dart';
import '../../features/review/screens/review_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/legal_document_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../repositories/content_repository_factory.dart';

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
      path: '/legal/privacy',
      builder: (BuildContext context, GoRouterState state) =>
          const LegalDocumentScreen(
            title: 'Privacy Policy',
            assetPath: 'PRIVACY_POLICY.md',
          ),
    ),
    GoRoute(
      path: '/legal/terms',
      builder: (BuildContext context, GoRouterState state) =>
          const LegalDocumentScreen(
            title: 'Terms of Use',
            assetPath: 'TERMS_OF_USE.md',
          ),
    ),
    GoRoute(
      path: '/legal/credits',
      builder: (BuildContext context, GoRouterState state) =>
          const LegalDocumentScreen(
            title: 'Credits & Attribution',
            assetPath: 'CREDITS.md',
          ),
    ),
    GoRoute(
      path: '/search',
      builder: (BuildContext context, GoRouterState state) =>
          const SearchScreen(),
    ),
    GoRoute(
      path: '/quiz',
      builder: (BuildContext context, GoRouterState state) =>
          const PracticeHomeScreen(),
    ),
    GoRoute(
      path: '/quiz/play',
      builder: (BuildContext context, GoRouterState state) {
        final String modeId =
            state.uri.queryParameters['mode'] ?? 'recognition';
        final String scriptsParam = state.uri.queryParameters['scripts'] ?? '';
        final List<String> scripts = scriptsParam.isEmpty
            ? ContentRepositoryFactory.availableContentIds
            : scriptsParam.split(',');
        final int questionCount =
            int.tryParse(state.uri.queryParameters['length'] ?? '') ?? 10;
        final String? itemsParam = state.uri.queryParameters['items'];
        final List<String>? reviewItemIds =
            itemsParam == null || itemsParam.isEmpty
            ? null
            : itemsParam.split(',');
        return PracticeSessionScreen(
          modeId: modeId,
          scripts: scripts,
          questionCount: questionCount,
          reviewItemIds: reviewItemIds,
        );
      },
    ),
    GoRoute(
      path: '/quiz/results',
      builder: (BuildContext context, GoRouterState state) =>
          const PracticeResultsScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (BuildContext context, GoRouterState state) =>
          const AnalyticsScreen(),
    ),
  ],
);
