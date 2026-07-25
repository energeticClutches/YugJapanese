import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/lesson_model.dart';
import '../../repositories/hiragana_repository.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/lesson_card.dart';
import '../progress/models/lesson_progress.dart';
import '../progress/providers/progress_providers.dart';

class HiraganaScreen extends ConsumerStatefulWidget {
  const HiraganaScreen({super.key});

  @override
  ConsumerState<HiraganaScreen> createState() => _HiraganaScreenState();
}

class _HiraganaScreenState extends ConsumerState<HiraganaScreen> {
  static const String _contentId = 'hiragana';
  late final Future<LessonModel?> _lessonFuture;

  @override
  void initState() {
    super.initState();
    _lessonFuture = HiraganaRepository().getLesson(1);
    Future<void>.microtask(
      () => ref.read(progressControllerProvider).loadProgress(_contentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressController = ref.watch(progressControllerProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Hiragana')),
      child: FutureBuilder<LessonModel?>(
        future: _lessonFuture,
        builder:
            (BuildContext context, AsyncSnapshot<LessonModel?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Coming Soon'));
          }

          final LessonModel lesson = snapshot.data!;
          final LessonProgress? progress = progressController.lessonProgress(
            _contentId,
            lesson.lessonNumber,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master the foundation of Japanese writing.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                LessonCard(
                  lessonTitle: lesson.title,
                  lessonSubtitle: lesson.description,
                  characters: lesson.characters
                      .map((character) => character.character)
                      .toList(growable: false),
                  progressLabel: _progressLabel(progress),
                  completionPercentage: progressController.completionPercentage(
                    _contentId,
                    1,
                  ),
                  onStartPressed: () =>
                      context.go('/practice/${lesson.lessonNumber}'),
                ),
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
