import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../repositories/content_repository_factory.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../models/review_item.dart';
import '../providers/review_providers.dart';
import '../widgets/empty_review_state.dart';
import '../widgets/review_card.dart';

class _ReviewDisplayInfo {
  const _ReviewDisplayInfo({
    required this.contentId,
    required this.lessonNumber,
    required this.title,
  });

  final String contentId;
  final int lessonNumber;
  final String title;
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
  return _ReviewDisplayInfo(
    contentId: contentId,
    lessonNumber: lessonNumber,
    title: 'Lesson ${lesson.characters.first.character}',
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
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
              const SizedBox(height: AppSpacing.lg),
              for (final _ReviewDisplayInfo info in resolved) ...[
                ReviewCard(
                  title: info.title,
                  onTap: () => context.go(
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
