class LessonProgress {
  const LessonProgress({
    required this.contentId,
    required this.lessonNumber,
    required this.isCompleted,
    required this.bestWritingAccuracy,
    required this.lastAccessedAt,
    this.completedAt,
  });

  final String contentId;
  final int lessonNumber;
  final bool isCompleted;
  final double bestWritingAccuracy;
  final DateTime lastAccessedAt;
  final DateTime? completedAt;

  LessonProgress copyWith({
    bool? isCompleted,
    double? bestWritingAccuracy,
    DateTime? lastAccessedAt,
    DateTime? completedAt,
  }) {
    return LessonProgress(
      contentId: contentId,
      lessonNumber: lessonNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      bestWritingAccuracy: bestWritingAccuracy ?? this.bestWritingAccuracy,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      completedAt: completedAt ?? this.completedAt,
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
    );
  }
}
