import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../repositories/content_repository_factory.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/review_item.dart';
import '../providers/review_providers.dart';
import '../widgets/empty_review_state.dart';
import '../widgets/review_card.dart';

/// Display names for the review list's script prefix. Local, matching the
/// same small per-screen maps `dashboard_screen.dart` and
/// `search_screen.dart` already keep — per PROJECT_RULES, this scale of
/// duplication is deliberate and not to be extracted into a service.
const Map<String, String> _scriptTitles = <String, String>{
  'hiragana': 'Hiragana',
  'katakana': 'Katakana',
  'kanji': 'Kanji',
};

class _ReviewDisplayInfo {
  const _ReviewDisplayInfo({
    required this.contentId,
    required this.lessonNumber,
    required this.title,
    required this.subtitle,
  });

  final String contentId;
  final int lessonNumber;
  final String title;
  final String subtitle;
}

/// How overdue a due item is, in words.
///
/// The scheduler already sorts `getDueReviews` by priority (overdue-ness,
/// inverted ease, lapse count), but none of that reached the screen — the
/// card took a title and nothing else, so a carefully priority-ordered
/// list rendered as a flat, undifferentiated stack. This surfaces the
/// overdue component, which is the part a learner can actually act on
/// (Milestone 23, Issue 1).
String _dueLabel(DateTime nextReview, DateTime now) {
  final int daysOverdue = now.difference(nextReview).inDays;
  if (daysOverdue <= 0) {
    return 'Due today';
  }
  return daysOverdue == 1 ? '1 day overdue' : '$daysOverdue days overdue';
}

Future<_ReviewDisplayInfo?> _resolveReviewItem(ReviewItem item) async {
  final List<String> parts = item.lessonId.split(':');
  if (parts.length != 2) {
    return null;
  }

  final String contentId = parts[0];
  final int? lessonNumber = int.tryParse(parts[1]);
  if (lessonNumber == null) {
    return null;
  }

  final repository = ContentRepositoryFactory.tryRepositoryFor(contentId);
  if (repository == null) {
    return null;
  }

  final lesson = await repository.getLesson(lessonNumber);
  if (lesson == null || lesson.characters.isEmpty) {
    return null;
  }

  // Was `'Lesson ${lesson.characters.first.character}'` — the literal word
  // "Lesson" glued to the lesson's first *glyph*, rendering as "Lesson あ".
  // That named neither the script nor the lesson number, so with more than
  // one script in rotation the list was a column of near-identical,
  // unidentifiable rows. `LessonModel` already carries `lessonNumber`,
  // `title` ("Lesson 1") and `description` ("Vowels"); this uses them
  // (Milestone 23, Issue 1).
  final String script = _scriptTitles[contentId] ?? contentId;
  return _ReviewDisplayInfo(
    contentId: contentId,
    lessonNumber: lessonNumber,
    title: '$script · ${lesson.title}',
    subtitle: '${lesson.description} · '
        '${_dueLabel(item.nextReview, DateTime.now())}',
  );
}

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ReviewItem>> dueReviewsAsync =
        ref.watch(dueReviewsProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Review')),
      child: dueReviewsAsync.when(
        data: (List<ReviewItem> items) => items.isEmpty
            ? const EmptyReviewState()
            : _ReviewList(items: items),
        loading: () => const LoadingIndicator(),
        error: (Object error, StackTrace stackTrace) =>
            const EmptyReviewState(),
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({required this.items});

  final List<ReviewItem> items;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ReviewDisplayInfo>>(
      future: Future.wait(items.map(_resolveReviewItem)).then(
        (List<_ReviewDisplayInfo?> results) =>
            results.whereType<_ReviewDisplayInfo>().toList(),
      ),
      builder: (context, snapshot) {
        // `hasError` first: `Future.wait` rejects if any lesson lookup
        // throws (a malformed or missing lessons asset), and on rejection
        // `hasData` stays false forever — so a bare `!hasData` check
        // turned a load failure into a permanent spinner with no way out.
        // Falls back to the same empty state the screen already shows
        // when nothing resolves, rather than inventing a new error UI.
        if (snapshot.hasError) {
          return const EmptyReviewState();
        }
        if (!snapshot.hasData) {
          return const LoadingIndicator();
        }

        final List<_ReviewDisplayInfo> resolved = snapshot.data!;
        if (resolved.isEmpty) {
          return const EmptyReviewState();
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Reviews",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              // Matches the dashboard's ReviewSummaryCard wording, so the
              // count a learner sees there and the list they land on
              // agree rather than one showing a number and the other
              // showing nothing (Milestone 23, Issue 1).
              Text(
                '${resolved.length} '
                '${resolved.length == 1 ? 'lesson' : 'lessons'} due · '
                'most fragile first',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final _ReviewDisplayInfo info in resolved) ...[
                ReviewCard(
                  title: info.title,
                  subtitle: info.subtitle,
                  onTap: () => context.push(
                    '/practice/${info.lessonNumber}?mode=review&content=${info.contentId}',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        );
      },
    );
  }
}
