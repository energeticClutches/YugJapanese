class LessonProgress {
  const LessonProgress({
    required this.contentId,
    required this.lessonNumber,
    required this.isCompleted,
    required this.bestWritingAccuracy,
    required this.lastAccessedAt,
    this.completedAt,
    this.lastCompletedAt,
  });

  final String contentId;
  final int lessonNumber;
  final bool isCompleted;
  final double bestWritingAccuracy;
  final DateTime lastAccessedAt;

  /// When this lesson was completed for the *first* time.
  final DateTime? completedAt;

  /// When this lesson was *most recently* completed.
  ///
  /// Distinct from [completedAt], which never moves after the first pass,
  /// and from [lastAccessedAt], which moves merely on opening a lesson.
  /// The learning streak counts completions, so it needs a date that
  /// advances on every re-completion but not on a browse — without this,
  /// re-studying an already-finished lesson recorded no streak activity
  /// (Milestone 31, Issue 6).
  final DateTime? lastCompletedAt;

  LessonProgress copyWith({
    bool? isCompleted,
    double? bestWritingAccuracy,
    DateTime? lastAccessedAt,
    DateTime? completedAt,
    DateTime? lastCompletedAt,
  }) {
    return LessonProgress(
      contentId: contentId,
      lessonNumber: lessonNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      bestWritingAccuracy: bestWritingAccuracy ?? this.bestWritingAccuracy,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      completedAt: completedAt ?? this.completedAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'contentId': contentId,
      'lessonNumber': lessonNumber,
      'isCompleted': isCompleted,
      'bestWritingAccuracy': bestWritingAccuracy,
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
    };
  }

  factory LessonProgress.fromMap(Map<String, dynamic> map) {
    return LessonProgress(
      contentId: map['contentId'] as String,
      lessonNumber: map['lessonNumber'] as int,
      isCompleted: map['isCompleted'] as bool,
      bestWritingAccuracy: (map['bestWritingAccuracy'] as num).toDouble(),
      lastAccessedAt: DateTime.parse(map['lastAccessedAt'] as String),
      completedAt: map['completedAt'] == null
          ? null
          : DateTime.parse(map['completedAt'] as String),
      // Absent in records saved before re-completion tracking existed; the
      // first completion is the best date those can offer.
      lastCompletedAt: DateTime.tryParse(
        (map['lastCompletedAt'] ?? map['completedAt'] ?? '') as String,
      ),
    );
  }
}
