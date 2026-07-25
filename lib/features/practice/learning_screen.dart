import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/learning_item.dart';
import '../../models/learning_step.dart';
import '../../repositories/content_repository_factory.dart';
import '../../repositories/lesson_repository.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../learning/models/kanji_example.dart';
import '../learning/widgets/example_word_card.dart';
import '../learning/widgets/radical_card.dart';
import '../learning/widgets/reading_section.dart';
import '../progress/providers/progress_providers.dart';
import '../review/providers/review_providers.dart';
import '../review/services/review_scheduler.dart';
import '../writing/models/stroke.dart';
import '../writing/models/stroke_point.dart';
import '../writing/models/writing_result.dart';
import '../writing/services/writing_evaluator.dart';
import '../writing/widgets/writing_result_card.dart';
import '../writing/writing_evaluator_provider.dart';
import 'learning_controller.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({
    super.key,
    required this.lessonNumber,
    this.isReviewMode = false,
    this.contentId = 'hiragana',
  });

  final int lessonNumber;
  final bool isReviewMode;
  final String contentId;

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  late final String _contentId = widget.contentId;
  late final LessonRepository _repository =
      ContentRepositoryFactory.repositoryFor(widget.contentId);
  late final LearningController _controller = LearningController(_repository);
  WritingResult? _writingResult;
  bool _isSavingCompletion = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _loadLesson();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    await _controller.startLesson(
      widget.lessonNumber,
      skipIntroduction: widget.isReviewMode,
    );
    if (!mounted || _controller.lessonNumber == null) {
      return;
    }
    await ref.read(progressControllerProvider).startLesson(
          contentId: _contentId,
          lessonNumber: widget.lessonNumber,
        );
  }

  WritingResult _evaluateCurrentItem(LearningItem item) {
    final WritingEvaluator evaluator = ref.read(writingEvaluatorProvider);
    final int expectedStrokeCount = item.strokeCount;
    final List<Stroke> strokes = List<Stroke>.generate(
      expectedStrokeCount,
      (int index) {
        final double inset = 24 + (index * 6).toDouble();
        final double size = 160 - (index * 4).toDouble();
        return Stroke(
          points: <StrokePoint>[
            StrokePoint(
              position: Offset(inset, inset),
              timestamp: DateTime.now(),
            ),
            StrokePoint(
              position: Offset(inset + size, inset + size),
              timestamp: DateTime.now(),
            ),
          ],
        );
      },
    );

    return evaluator.evaluate(
      strokes: strokes,
      expectedStrokeCount: expectedStrokeCount,
      expectedBoundingBox: const Rect.fromLTWH(24, 24, 160, 160),
      canvasSize: const Size(256, 256),
      isDrawingCompleted: true,
    );
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _continueAfterResult() async {
    final session = _controller.session;
    final result = _writingResult;
    if (session == null || result == null) {
      return;
    }

    final bool isFinalCharacter =
        session.currentCharacterIndex == session.totalCharacters - 1;
    if (isFinalCharacter) {
      if (_isSavingCompletion) {
        return;
      }
      setState(() {
        _isSavingCompletion = true;
      });
      await ref.read(progressControllerProvider).completeLesson(
            contentId: _contentId,
            lessonNumber: session.lessonNumber,
            writingAccuracy: result.accuracy,
          );

      final String lessonId = '$_contentId:${session.lessonNumber}';
      final ReviewScheduler reviewScheduler =
          ref.read(reviewSchedulerProvider);
      if (widget.isReviewMode) {
        await reviewScheduler.recordSuccessfulReview(lessonId);
      } else {
        await reviewScheduler.scheduleInitialReview(lessonId);
      }
      ref.invalidate(dueReviewsProvider);

      if (!mounted) {
        return;
      }
      context.go(widget.isReviewMode ? '/review' : '/$_contentId');
      return;
    }

    setState(() {
      _writingResult = null;
    });
    _controller.nextCharacter();
  }

  @override
  Widget build(BuildContext context) {
    final int? lessonNumber = _controller.lessonNumber;
    final LearningStep currentStep = _controller.currentStep;
    final currentCharacter = _controller.currentCharacter;
    final session = _controller.session;

    if (currentStep == LearningStep.completed &&
        currentCharacter != null &&
        _writingResult == null) {
      final LearningItem item = currentCharacter;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _writingResult != null) {
          return;
        }
        setState(() {
          _writingResult = _evaluateCurrentItem(item);
        });
      });
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Learning Flow')),
      child: lessonNumber == null || session == null || currentCharacter == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Lesson $lessonNumber',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Current Character: ${currentCharacter.symbol}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Current Step: ${_describeStep(currentStep)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Character ${session.currentCharacterIndex + 1} of ${session.totalCharacters}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (currentStep == LearningStep.completed)
                  if (_writingResult == null)
                    const Center(child: CircularProgressIndicator())
                  else
                    WritingResultCard(
                      result: _writingResult!,
                      onContinue: _continueAfterResult,
                    )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            currentCharacter.symbol,
                            style: Theme.of(context).textTheme.displayLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            currentCharacter.primaryReading,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            currentCharacter.meaning,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          if (currentStep == LearningStep.introduction &&
                              currentCharacter.radical != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            ReadingSection(
                              onReadings: [
                                currentCharacter.primaryReading,
                                ...currentCharacter.secondaryReadings,
                              ],
                              kunReadings: currentCharacter.kunReadings,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            RadicalCard(
                              radical: currentCharacter.radical!,
                              strokeCount: currentCharacter.strokeCount,
                            ),
                          ],
                          if (currentStep == LearningStep.introduction &&
                              currentCharacter.examples.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Example',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (final KanjiExample example
                                in currentCharacter.examples) ...[
                              ExampleWordCard(example: example),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                if (currentStep != LearningStep.completed) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _controller.previousStep,
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: _controller.nextStep,
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: currentStep == LearningStep.completed
                            ? _continueAfterResult
                            : _controller.nextCharacter,
                        child: const Text('Next Character'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            _writingResult = null;
                          });
                          _controller.restartLesson();
                        },
                        child: const Text('Restart'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _describeStep(LearningStep step) {
    switch (step) {
      case LearningStep.introduction:
        return 'Introduction';
      case LearningStep.strokeOrder:
        return 'Stroke Order';
      case LearningStep.tracing:
        return 'Tracing';
      case LearningStep.freeWriting:
        return 'Free Writing';
      case LearningStep.completed:
        return 'Completed';
    }
  }
}
