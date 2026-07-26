/// Per-script analytics breakdown (Hiragana/Katakana/Kanji).
///
/// [averageQuizAccuracy] is approximated from every `PracticeResult` whose
/// `contentIds` include this script — `PracticeResult` records session-level
/// accuracy across all scripts touched in that session, not a per-script
/// breakdown, so this is an approximation rather than an exact per-item
/// figure.
class ScriptAnalytics {
  const ScriptAnalytics({
    required this.contentId,
    required this.completionPercentage,
    required this.averageWritingAccuracy,
    required this.averageQuizAccuracy,
    required this.reviewsDue,
    required this.practiceSessions,
  });

  final String contentId;
  final double completionPercentage;
  final double averageWritingAccuracy;
  final double averageQuizAccuracy;
  final int reviewsDue;
  final int practiceSessions;
}
