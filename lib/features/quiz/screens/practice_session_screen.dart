import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/practice_question.dart';
import '../models/practice_session.dart';
import '../providers/practice_providers.dart';
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

  @override
  Widget build(BuildContext context) {
    final PracticeService service = ref.watch(practiceServiceProvider);
    final PracticeSession? session = service.currentSession;

    if (service.isGenerating || session == null) {
      return const AppScaffold(child: LoadingIndicator());
    }

    if (session.questions.isEmpty) {
      return AppScaffold(
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
      return const AppScaffold(child: LoadingIndicator());
    }

    final PracticeQuestion question = session.currentQuestion!;

    return AppScaffold(
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
