enum PracticeDifficulty { beginner, intermediate, advanced }

/// Static definition of a practice/quiz mode. Not persisted — the full set
/// lives in [PracticeGenerator.catalog]; only completed sessions
/// ([PracticeResult]) are saved.
class PracticeMode {
  const PracticeMode({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.difficulty,
    required this.supportedScripts,
  });

  final String id;
  final String title;
  final String description;

  /// Resolved to a concrete icon by the widget layer, keeping this model
  /// free of Flutter dependencies (matches [Achievement.iconKey]).
  final String iconKey;

  final PracticeDifficulty difficulty;
  final List<String> supportedScripts;
}
