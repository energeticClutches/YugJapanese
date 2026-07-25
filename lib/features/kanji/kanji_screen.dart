import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/lesson_model.dart';
import '../../repositories/kanji_repository.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/lesson_card.dart';
import '../progress/models/lesson_progress.dart';
import '../progress/providers/progress_providers.dart';
import '../progress/services/progress_controller.dart';

class KanjiScreen extends ConsumerStatefulWidget {
  const KanjiScreen({super.key});

  @override
  ConsumerState<KanjiScreen> createState() => _KanjiScreenState();
}

class _KanjiScreenState extends ConsumerState<KanjiScreen> {
  static const String _contentId = 'kanji';
  late final Future<List<LessonModel>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = KanjiRepository().getAllLessons();
    Future<void>.microtask(
      () => ref.read(progressControllerProvider).loadProgress(_contentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProgressController progressController =
        ref.watch(progressControllerProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Kanji')),
      child: FutureBuilder<List<LessonModel>>(
        future: _lessonsFuture,
        builder:
            (BuildContext context, AsyncSnapshot<List<LessonModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<LessonModel> lessons =
              snapshot.data ?? const <LessonModel>[];
          if (snapshot.hasError || lessons.isEmpty) {
            return const Center(child: Text('Coming Soon'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn beginner (JLPT N5) Kanji.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final LessonModel lesson in lessons) ...[
                  LessonCard(
                    lessonTitle: lesson.title,
                    lessonSubtitle: lesson.description,
                    characters: lesson.characters
                        .map((character) => character.character)
                        .toList(growable: false),
                    progressLabel: _progressLabel(
                      progressController.lessonProgress(
                        _contentId,
                        lesson.lessonNumber,
                      ),
                    ),
                    completionPercentage: progressController
                            .lessonProgress(_contentId, lesson.lessonNumber)
                            ?.isCompleted ==
                        true
                        ? 100
                        : 0,
                    onStartPressed: () => context.go(
                      '/practice/${lesson.lessonNumber}?content=$_contentId',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _progressLabel(LessonProgress? progress) {
    if (progress == null) {
      return 'Not Started';
    }
    return progress.isCompleted ? 'Completed' : 'In Progress';
  }
}
