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

  /// Tracks which step `_strokes` was last drawn for, alongside
  /// [_strokesForItemId]. Reset used to fire only on a character change,
  /// which is what let traced ink survive into the free-writing canvas:
  /// the generic "Next" button advances `_controller.nextStep()` directly
  /// and never goes through `_submitWriting`, so nothing cleared `_strokes`
  /// on that path. Tracking the step too, and checking it unconditionally
  /// on every build, resets the canvas on *any* step transition regardless
  /// of which button caused it (Milestone 22, Issue 3 — P0).
  LearningStep? _strokesForStep;

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

      // Review mode belongs to the review queue, not the lesson ladder, so it
      // keeps returning to /review rather than offering the next lesson.
      final int? nextLesson =
          widget.isReviewMode ? null : await _controller.nextLessonNumber();

      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingCompletion = false;
      });

      if (!widget.isReviewMode) {
        final bool goToNext =
            await _showLessonCompleteDialog(lessonAccuracy, nextLesson);
        if (!mounted) {
          return;
        }
        if (goToNext && nextLesson != null) {
          // Replace rather than push: chaining lessons would otherwise stack
          // a screen per lesson, so Back would walk the learner through every
          // lesson they just finished instead of returning to the list.
          context.pushReplacement(
            '/practice/$nextLesson?content=$_contentId',
          );
          return;
        }
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

  /// Confirms the lesson was saved and offers the next step.
  ///
  /// Returns true when the learner chose to continue to [nextLesson]. The
  /// flow previously dropped straight back to the lesson list with no such
  /// action, so continuing meant finding the next lesson by hand (BUG-008).
  /// Not dismissible: both outcomes navigate, so there is no state to fall
  /// back to.
  Future<bool> _showLessonCompleteDialog(
    double accuracy,
    int? nextLesson,
  ) async {
    final int lessonNumber = _controller.lessonNumber ?? widget.lessonNumber;
    final bool isModuleComplete = nextLesson == null;
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Lesson $lessonNumber complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Writing accuracy: ${(accuracy * 100).round()}%'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isModuleComplete
                    ? 'That was the last lesson here. Your progress is saved.'
                    : 'Your progress is saved. Lesson $nextLesson is ready '
                        'when you are.',
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Back to Lessons'),
            ),
            if (!isModuleComplete)
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Next Lesson'),
              ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final int? lessonNumber = _controller.lessonNumber;
    final LearningStep currentStep = _controller.currentStep;
    final currentCharacter = _controller.currentCharacter;
    final session = _controller.session;

    // Moving to a different character clears the canvas, drops the stale
    // reference strokes, and forgets which step the canvas belongs to.
    if (currentCharacter != null &&
        _strokesForItemId != currentCharacter.id) {
      _strokesForItemId = currentCharacter.id;
      _strokes = <Stroke>[];
      _guideStrokes = null;
      _writingResult = null;
      _strokesForStep = currentStep;
    } else if (_strokesForStep != currentStep) {
      // Same character, different step: this is the tracing -> free
      // writing transition (and every other step change). Clearing here —
      // unconditionally, on every path that changes `currentStep` — is
      // what makes the reset independent of which button triggered it
      // (Milestone 22, Issue 3). Guide strokes are untouched: they belong
      // to the character, not the step, so re-fetching them on every step
      // change would just be a wasted flicker.
      _strokesForStep = currentStep;
      _strokes = <Stroke>[];
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

    // Arriving at the result step always produces a score. "Check my
    // writing" is not the only way in: the Next button steps freeWriting ->
    // completed, and "Next Character" on the final character short-circuits
    // to completed via [LearningSession.nextCharacter]. Those paths left
    // `_writingResult` null, and the result step rendered a spinner for that
    // case — a spinner with no async work behind it, so it never resolved and
    // `_continueAfterResult` bailed on its own null-result guard, stranding
    // the learner (BUG-007). Grading here covers every path in. An untouched
    // canvas scores 0 with "Finish the character before submitting", which is
    // the honest outcome for skipping the step.
    if (currentStep == LearningStep.completed &&
        currentCharacter != null &&
        _writingResult == null) {
      _writingResult = _evaluateDrawnStrokes(currentCharacter);
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
                  // Four stacked status lines (title, character, step,
                  // position) at near-identical spacing used to read as an
                  // undifferentiated debug dump rather than a page header.
                  // The step and position facts are merged onto one line —
                  // same "·"-joined pattern already used for compact facts
                  // elsewhere (e.g. the dashboard's script summary cards) —
                  // and the gap under the title is tightened so the title
                  // reads as a heading with a subtitle under it, not four
                  // equally-weighted rows (Milestone 21, Issue 4).
                  Text(
                    'Lesson $lessonNumber',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Current Character: ${currentCharacter.symbol}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${_describeStep(currentStep)} · '
                    'Character ${session.currentCharacterIndex + 1} of ${session.totalCharacters}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (currentStep == LearningStep.completed)
                    // Non-null by construction: the block above grades the
                    // attempt on arrival at this step.
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
                    // Larger than the md gap between the two buttons in a
                    // row: this separates two different actions (advance
                    // within the character vs. move to the next character
                    // or restart), not two buttons doing one job, so it
                    // reads as a break between stages rather than a single
                    // four-button block (Milestone 21, Issue 4).
                    const SizedBox(height: AppSpacing.lg),
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
          // Tracing isn't graded — _submitWriting just clears the canvas
          // and moves on to free writing — so "Check my writing" there
          // claimed an evaluation that never happens (Milestone 21,
          // Issue 5). Free writing keeps the default label; that's the
          // step _evaluateDrawnStrokes actually scores.
          submitLabel:
              isTracing ? 'Continue to Free Writing' : 'Check my writing',
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

  /// Minimum tracing accuracy — scored with the exact same evaluator used
  /// for the graded free-writing attempt — before "Continue to Free
  /// Writing" is allowed to advance. Deliberately lenient: tracing has a
  /// visible guide underneath the ink, so this only catches strokes with
  /// essentially no relationship to the character (drawn somewhere else
  /// entirely, or a scribble), not an imperfect-but-genuine trace. Tracing
  /// previously had no validation at all — the button only checked
  /// `hasInk`, so it advanced on any non-empty canvas regardless of what
  /// was actually drawn (Milestone 22, Issue 2).
  static const double _minTracingAccuracyToAdvance = 0.3;

  /// Handles "Continue to Free Writing" / "Check my writing".
  ///
  /// Tracing is now scored against the guide (Issue 2) but is not the
  /// graded attempt — only free writing's result is kept and shown via
  /// [WritingResultCard] ([LearningSession.nextStep] maps
  /// freeWriting -> completed). Canvas reset on the way out of tracing is
  /// handled once, unconditionally, in [build] rather than here — see
  /// `_strokesForStep` — so it applies no matter which button ends the
  /// step (Issue 3).
  void _submitWriting(LearningItem item) {
    if (_controller.currentStep == LearningStep.tracing) {
      final WritingResult traceResult = _evaluateDrawnStrokes(item);
      if (traceResult.accuracy < _minTracingAccuracyToAdvance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trace closer to the guide before continuing.'),
          ),
        );
        return;
      }
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
