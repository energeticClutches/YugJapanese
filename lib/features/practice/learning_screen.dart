import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/learning_item.dart';
import '../../models/learning_step.dart';
import '../../repositories/content_repository_factory.dart';
import '../../repositories/lesson_repository.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../audio/providers/audio_providers.dart';
import '../audio/widgets/audio_button.dart';
import '../learning/models/kanji_example.dart';
import '../learning/widgets/example_word_card.dart';
import '../learning/widgets/radical_card.dart';
import '../learning/widgets/reading_section.dart';
import '../progress/providers/progress_providers.dart';
import '../review/providers/review_providers.dart';
import '../review/services/review_scheduler.dart';
import '../settings/models/app_settings.dart';
import '../settings/providers/settings_providers.dart';
import '../writing/models/stroke.dart';
import '../writing/models/stroke_template.dart';
import '../writing/models/writing_result.dart';
import '../writing/providers/stroke_data_providers.dart';
import '../writing/services/writing_evaluator.dart';
import '../writing/widgets/stroke_order_player.dart';
import '../writing/widgets/writing_practice_panel.dart';
import '../writing/widgets/writing_result_card.dart';
import '../writing/writing_evaluator_provider.dart';
import 'learning_controller.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({
    super.key,
    required this.lessonNumber,
    this.isReviewMode = false,
    this.contentId = 'hiragana',
    this.startCharacterId,
  });

  final int lessonNumber;
  final bool isReviewMode;
  final String contentId;

  /// If set, the lesson opens with this character selected instead of the
  /// first one — used when arriving from search/detail lookup.
  final String? startCharacterId;

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
  String? _autoPlayedItemId;

  /// Accuracy for each character finished in this session, so the lesson is
  /// scored on the whole attempt rather than on whichever character happened
  /// to be last.
  final List<double> _characterAccuracies = <double>[];

  /// Strokes the user has drawn for the current character. Reset whenever
  /// the character or the lesson changes.
  List<Stroke> _strokes = <Stroke>[];

  /// Reference strokes for the current character, resolved from the
  /// bundled KanjiVG-derived data. Null when none are bundled — the
  /// canvas then falls back to free drawing with no guide.
  List<StrokeTemplate>? _guideStrokes;

  /// Size of the canvas the user last drew on, so evaluation happens in
  /// the same coordinate space as the input.
  Size? _lastCanvasSize;

  /// Tracks which character `_strokes`/`_guideStrokes` belong to.
  String? _strokesForItemId;

  /// True while a finger is actively drawing a stroke on the canvas.
  /// Applied to the page's [SingleChildScrollView] as
  /// `NeverScrollableScrollPhysics` for the duration — see
  /// [WritingCanvas.onDrawingActive] for why this is necessary (a
  /// near-vertical stroke and "scroll the page" are the same gesture from
  /// the ScrollView's perspective; freezing scroll during a stroke is what
  /// stops the two from fighting over one touch).
  bool _isDrawingActive = false;

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
      startCharacterId: widget.startCharacterId,
    );
    if (!mounted || _controller.lessonNumber == null) {
      return;
    }
    await ref
        .read(progressControllerProvider)
        .startLesson(contentId: _contentId, lessonNumber: widget.lessonNumber);
  }

  /// Scores what the user actually drew on the canvas.
  ///
  /// Before the writing canvas existed this method fabricated synthetic
  /// diagonal strokes and scored those, so every recorded "writing
  /// accuracy" was machine-generated rather than earned. It now evaluates
  /// [_strokes] — the real captured input — against the character's
  /// expected stroke count, using the canvas's own size and the reference
  /// glyph's bounding box so coverage/placement are measured in the same
  /// coordinate space the user drew in.
  WritingResult _evaluateDrawnStrokes(LearningItem item) {
    final WritingEvaluator evaluator = ref.read(writingEvaluatorProvider);
    final Size canvasSize = _lastCanvasSize ?? const Size(300, 300);

    // The reference strokes (when bundled) give the character's real
    // extent; without them fall back to the conventional centred square
    // most handwriting practice sheets use.
    Rect expectedBox = Rect.fromLTWH(
      canvasSize.width * 0.1,
      canvasSize.height * 0.1,
      canvasSize.width * 0.8,
      canvasSize.height * 0.8,
    );
    final List<StrokeTemplate>? guide = _guideStrokes;
    if (guide != null && guide.isNotEmpty) {
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = -double.infinity;
      double maxY = -double.infinity;
      for (final StrokeTemplate stroke in guide) {
        for (final Offset p in stroke.scaledTo(canvasSize)) {
          minX = math.min(minX, p.dx);
          minY = math.min(minY, p.dy);
          maxX = math.max(maxX, p.dx);
          maxY = math.max(maxY, p.dy);
        }
      }
      if (minX.isFinite && maxX > minX && maxY > minY) {
        expectedBox = Rect.fromLTRB(minX, minY, maxX, maxY);
      }
    }

    return evaluator.evaluate(
      strokes: _strokes,
      expectedStrokeCount: item.strokeCount,
      expectedBoundingBox: expectedBox,
      canvasSize: canvasSize,
      isDrawingCompleted: _strokes.isNotEmpty,
      referenceStrokes: guide,
    );
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _maybeAutoPlayPronunciation(LearningItem item) {
    if (_autoPlayedItemId == item.id) {
      return;
    }
    final settings = ref.read(currentSettingsProvider).settings;
    if (!settings.soundEnabled || !settings.autoPlayAudio) {
      return;
    }
    _autoPlayedItemId = item.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(audioServiceProvider)
          .play(id: item.id, assetPath: item.audioAsset, script: _contentId);
    });
  }

  Future<void> _continueAfterResult() async {
    final session = _controller.session;
    final result = _writingResult;
    if (session == null || result == null) {
      return;
    }

    _characterAccuracies.add(result.accuracy);

    final bool isFinalCharacter =
        session.currentCharacterIndex == session.totalCharacters - 1;
    if (isFinalCharacter) {
      if (_isSavingCompletion) {
        return;
      }
      setState(() {
        _isSavingCompletion = true;
      });
      final double lessonAccuracy = _characterAccuracies.isEmpty
          ? result.accuracy
          : _characterAccuracies.reduce((double a, double b) => a + b) /
              _characterAccuracies.length;

      await ref
          .read(progressControllerProvider)
          .completeLesson(
            contentId: _contentId,
            lessonNumber: session.lessonNumber,
            writingAccuracy: lessonAccuracy,
          );

      final String lessonId = '$_contentId:${session.lessonNumber}';
      final ReviewScheduler reviewScheduler = ref.read(reviewSchedulerProvider);
      if (widget.isReviewMode) {
        // Scored, not assumed: a weak attempt sends the lesson back down the
        // interval ladder instead of pushing it further away.
        await reviewScheduler.recordReview(
          lessonId,
          accuracy: lessonAccuracy,
        );
      } else {
        await reviewScheduler.scheduleInitialReview(
          lessonId,
          accuracy: lessonAccuracy,
        );
      }
      ref.invalidate(dueReviewsProvider);

      if (!mounted) {
        return;
      }
      // Pop back to whatever screen pushed this lesson (the script's lesson
      // list, or the review list in review mode) rather than `go()`, which
      // would collapse the whole navigation stack down to a single entry
      // and break Back navigation afterward. Falls back to `go()` only if
      // there's nothing left to pop to.
      final String fallbackRoute = widget.isReviewMode ? '/review' : '/$_contentId';
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallbackRoute);
      }
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

    // Moving to a different character clears the canvas and pulls that
    // character's reference strokes.
    if (currentCharacter != null &&
        _strokesForItemId != currentCharacter.id) {
      _strokesForItemId = currentCharacter.id;
      _strokes = <Stroke>[];
      _guideStrokes = null;
      _writingResult = null;
    }

    if (currentCharacter != null) {
      // `characterStrokesProvider` is a cached FutureProvider keyed by
      // symbol, so watching it here is cheap after the first resolve.
      final CharacterStrokes? resolved = ref
          .watch(characterStrokesProvider(currentCharacter.symbol))
          .asData
          ?.value;
      if (resolved != null) {
        _guideStrokes = resolved.strokes;
      }
    }

    if (currentStep == LearningStep.introduction && currentCharacter != null) {
      _maybeAutoPlayPronunciation(currentCharacter);
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Learning Flow')),
      child: lessonNumber == null || session == null || currentCharacter == null
          ? const LoadingIndicator()
          : SingleChildScrollView(
              physics: _isDrawingActive
                  ? const NeverScrollableScrollPhysics()
                  : null,
              child: Column(
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
                      const LoadingIndicator()
                    else
                      WritingResultCard(
                        result: _writingResult!,
                        onContinue: _continueAfterResult,
                      )
                  else if (currentStep == LearningStep.strokeOrder ||
                      currentStep == LearningStep.tracing ||
                      currentStep == LearningStep.freeWriting)
                    _buildWritingStep(context, currentStep, currentCharacter)
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
                            AudioButton(
                              key: ValueKey(currentCharacter.id),
                              id: currentCharacter.id,
                              assetPath: currentCharacter.audioAsset,
                              script: _contentId,
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
                            // Optional shape/sound hint, shown only while the
                            // character is being introduced so it does not
                            // crowd the tracing and writing steps.
                            if (currentStep == LearningStep.introduction &&
                                (currentCharacter.notes?.isNotEmpty ??
                                    false)) ...[
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Flexible(
                                    child: Text(
                                      currentCharacter.notes!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                              _autoPlayedItemId = null;
                              _characterAccuracies.clear();
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
            ),
    );
  }

  /// Builds the stroke-order, tracing, or free-writing step.
  ///
  /// All three honour the user's Learning settings: [AppSettings.showGrid]
  /// toggles the practice grid, [AppSettings.showStrokeGuide] toggles the
  /// reference stroke overlay behind the canvas, and
  /// [AppSettings.animationSpeed] scales the stroke-order playback.
  Widget _buildWritingStep(
    BuildContext context,
    LearningStep step,
    LearningItem item,
  ) {
    final AppSettings settings = ref.watch(currentSettingsProvider).settings;
    final List<StrokeTemplate>? guide = _guideStrokes;

    if (step == LearningStep.strokeOrder) {
      if (guide == null || guide.isEmpty) {
        return _NoStrokeDataCard(symbol: item.symbol);
      }
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Watch the stroke order, then trace it yourself.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              StrokeOrderPlayer(
                // Rebuild the player from scratch per character so the
                // animation restarts rather than resuming mid-way.
                key: ValueKey<String>('stroke-order-${item.id}'),
                strokes: guide,
                strokeDuration: _strokeDuration(settings.animationSpeed),
                showGrid: settings.showGrid,
              ),
            ],
          ),
        ),
      );
    }

    final bool isTracing = step == LearningStep.tracing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: WritingPracticePanel(
          strokes: _strokes,
          expectedStrokeCount: item.strokeCount,
          // Tracing shows the reference behind the ink; free writing is
          // from memory. Either way the user's Stroke Guides preference
          // wins — turning it off removes the overlay everywhere.
          guideStrokes:
              isTracing && settings.showStrokeGuide ? guide : null,
          showGrid: settings.showGrid,
          instructions: isTracing
              ? 'Trace over the guide with your finger.'
              : 'Now write ${item.symbol} from memory.',
          onStrokesChanged: (List<Stroke> strokes) {
            setState(() {
              _strokes = strokes;
            });
          },
          onCanvasSize: (Size size) => _lastCanvasSize = size,
          onDrawingActive: (bool active) {
            setState(() {
              _isDrawingActive = active;
            });
          },
          onSubmit: () => _submitWriting(item),
        ),
      ),
    );
  }

  /// Handles "Check my writing".
  ///
  /// Tracing hands off to free writing with a fresh canvas; free writing
  /// is the graded attempt, so it evaluates the real strokes and advances
  /// to the result step ([LearningSession.nextStep] maps
  /// freeWriting -> completed).
  void _submitWriting(LearningItem item) {
    if (_controller.currentStep == LearningStep.tracing) {
      setState(() {
        _strokes = <Stroke>[];
      });
      _controller.nextStep();
      return;
    }

    setState(() {
      _writingResult = _evaluateDrawnStrokes(item);
    });
    _controller.nextStep();
  }

  Duration _strokeDuration(AnimationSpeed speed) {
    switch (speed) {
      case AnimationSpeed.slow:
        return const Duration(milliseconds: 1400);
      case AnimationSpeed.normal:
        return const Duration(milliseconds: 900);
      case AnimationSpeed.fast:
        return const Duration(milliseconds: 500);
    }
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

/// Shown when a character has no bundled reference strokes. Every
/// character currently taught does have them, so this is a graceful
/// fallback for future content added before its stroke data, not an
/// expected state.
class _NoStrokeDataCard extends StatelessWidget {
  const _NoStrokeDataCard({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Text(
              symbol,
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Stroke order data is not available for this character yet. '
              'You can still practise writing it in the next step.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
