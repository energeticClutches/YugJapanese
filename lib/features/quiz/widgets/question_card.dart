import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../audio/models/audio_item.dart';
import '../../audio/widgets/audio_button.dart';
import '../models/practice_question.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
  });

  final PracticeQuestion question;
  final int questionNumber;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isListening = question.questionType == QuestionType.listening;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Text(
              'Question $questionNumber of $totalQuestions',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (isListening)
              AudioButton(
                key: ValueKey(question.id),
                id: question.metadata?['audioId'] as String? ??
                    question.learningItem.id,
                assetPath: question.metadata?['audioAssetPath'] as String? ??
                    question.learningItem.audioAsset,
                script: question.metadata?['audioScript'] as String? ??
                    question.contentId,
                type: AudioType.character,
              )
            else
              Text(
                question.prompt,
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
            if (isListening) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                question.prompt,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
