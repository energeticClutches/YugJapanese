import '../../../models/learning_item.dart';

enum QuestionType { recognition, meaning, reading, listening }

/// A single quiz question. One shared model for every [PracticeMode] —
/// mode selection only decides which [QuestionType] builder(s)
/// `PracticeGenerator` uses to produce these.
class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.learningItem,
    required this.contentId,
    required this.questionType,
    required this.prompt,
    required this.choices,
    required this.correctAnswer,
    this.metadata,
  });

  final String id;
  final LearningItem learningItem;
  final String contentId;
  final QuestionType questionType;
  final String prompt;
  final List<String> choices;
  final String correctAnswer;
  final Map<String, dynamic>? metadata;
}
