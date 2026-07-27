import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/practice_question.dart';
import '../models/practice_session.dart';
import '../providers/practice_providers.dart';
import '../services/practice_generator.dart';
import '../services/practice_service.dart';
import '../widgets/answer_option.dart';
import '../widgets/question_card.dart';

class PracticeSessionScreen extends ConsumerStatefulWidget {
  const PracticeSessionScreen({
    super.key,
    required this.modeId,
    required this.scripts,
    required this.questionCount,
    this.reviewItemIds,
  });

  final String modeId;
  final List<String> scripts;
  final int questionCount;

  /// When set (non-empty), the session is scoped to exactly these item ids
  /// — the results screen's "Review Mistakes" action — instead of a fresh
  /// generated session.
  final List<String>? reviewItemIds;

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  bool _started = false;
  bool _navigatedToResults = false;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (_started) {
      return;
    }
    _started = true;
    final PracticeService service = ref.read(practiceServiceProvider);
    final List<String>? reviewIds = widget.reviewItemIds;
    if (reviewIds != null && reviewIds.isNotEmpty) {
      service.startReviewMistakes(reviewIds);
    } else {
      service.startSession(
        modeId: widget.modeId,
        scripts: widget.scripts,
        questionCount: widget.questionCount,
      );
    }
  }

  /// "Review Mistakes" and "Retry" are already functionally distinct —
  /// `startReviewMistakes` scopes to exactly the missed items,
  /// `startSession` generates a fresh full-length session — but this
  /// screen showed no indication of which one was running: no `AppBar`
  /// anywhere, just "Question X of Y" either way. Two workflows that look
  /// pixel-identical read as "the same action" no matter how different
  /// the underlying item set is (Milestone 23, Issue 2). Reuses
  /// `PracticeGenerator.modeById`, the same lookup already used by the
  /// results and dashboard screens, rather than a second title table.
  String get _screenTitle {
    final List<String>? reviewIds = widget.reviewItemIds;
    if (reviewIds != null && reviewIds.isNotEmpty) {
      return 'Review Mistakes';
    }
    return PracticeGenerator.modeById(widget.modeId)?.title ?? 'Practice';
  }

  @override
  Widget build(BuildContext context) {
    final PracticeService service = ref.watch(practiceServiceProvider);
    final PracticeSession? session = service.currentSession;
    final AppBar appBar = AppBar(title: Text(_screenTitle));

    // `!_started` is load-bearing, not defensive padding. `PracticeService`
    // is an app-lifetime singleton and nothing ever calls its
    // `clearSession()` (it has no callers at all), so after any completed
    // quiz `currentSession` stays populated and `isComplete` stays true
    // forever. `_start()` runs in a post-frame callback — i.e. *after*
    // this first build — so without this guard the first build of a
    // freshly-pushed session screen saw the previous, already-complete
    // session: not generating, not null, not empty, `isComplete` true.
    // It therefore fell into the `isComplete` branch below and immediately
    // `pushReplacement`ed to `/quiz/results`, showing the OLD result.
    //
    // That is Milestone 23's Issue 4 ("multiple Quiz menu buttons navigate
    // to the same screen regardless of which option is selected") — every
    // mode card bounced to the same stale results screen — and also the
    // functional half of Issue 2: "Review Mistakes" and "Retry" both did
    // nothing except bounce back to the results screen they were launched
    // from, which is exactly why they looked like the same action. Both
    // only reproduce after finishing one quiz, which is why a fresh
    // install looks fine.
    if (!_started || service.isGenerating || session == null) {
      return AppScaffold(appBar: appBar, child: const LoadingIndicator());
    }

    if (session.questions.isEmpty) {
      return AppScaffold(
        appBar: appBar,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Not enough content available for this mode yet.'),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/quiz'),
                child: const Text('Return to Practice'),
              ),
            ],
          ),
        ),
      );
    }

    if (session.isComplete) {
      if (!_navigatedToResults) {
        _navigatedToResults = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Replace this session on the stack rather than `go()`, which
            // would reset the whole navigation stack back to a single
            // entry and break Back navigation from the results screen.
            context.pushReplacement('/quiz/results');
          }
        });
      }
      return AppScaffold(appBar: appBar, child: const LoadingIndicator());
    }

    final PracticeQuestion question = session.currentQuestion!;

    return AppScaffold(
      appBar: appBar,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            QuestionCard(
              question: question,
              questionNumber: session.currentIndex + 1,
              totalQuestions: session.questions.length,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final String choice in question.choices) ...[
              AnswerOption(
                label: choice,
                state: _stateFor(choice, question),
                onTap: _selectedAnswer == null ? () => _selectAnswer(choice) : null,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  AnswerOptionState _stateFor(String choice, PracticeQuestion question) {
    if (_selectedAnswer == null) {
      return AnswerOptionState.neutral;
    }
    if (choice == question.correctAnswer) {
      return AnswerOptionState.revealedCorrect;
    }
    if (choice == _selectedAnswer) {
      return AnswerOptionState.selectedIncorrect;
    }
    return AnswerOptionState.neutral;
  }

  Future<void> _selectAnswer(String choice) async {
    setState(() => _selectedAnswer = choice);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) {
      return;
    }
    await ref.read(practiceServiceProvider).submitAnswer(choice);
    if (!mounted) {
      return;
    }
    setState(() => _selectedAnswer = null);
  }
}
