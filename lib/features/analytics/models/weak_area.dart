enum WeakAreaType { lowWritingAccuracy, missedQuizItem, overdueReview }

/// One item or lesson flagged as needing attention. [severity] is only
/// meaningful relative to other [WeakArea]s of the same [type] (used for
/// sorting worst-first) — its unit differs per type (accuracy deficit,
/// miss count, days overdue).
class WeakArea {
  const WeakArea({
    required this.type,
    required this.contentId,
    required this.itemId,
    required this.label,
    required this.description,
    required this.severity,
  });

  final WeakAreaType type;
  final String contentId;
  final String itemId;
  final String label;
  final String description;
  final double severity;
}
