class WritingResult {
  const WritingResult({
    required this.accuracy,
    required this.strokeCountCorrect,
    required this.completed,
    required this.feedbackMessage,
  });

  final double accuracy;
  final bool strokeCountCorrect;
  final bool completed;
  final String feedbackMessage;
}
