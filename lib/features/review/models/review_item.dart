class ReviewItem {
  const ReviewItem({
    required this.lessonId,
    required this.nextReview,
    this.lastReviewed,
    required this.reviewCount,
    required this.easeFactor,
    required this.intervalDays,
    this.lapses = 0,
  });

  /// Generic identifier for the reviewed lesson, e.g. "hiragana:1".
  final String lessonId;
  final DateTime nextReview;
  final DateTime? lastReviewed;
  final int reviewCount;

  /// How readily this lesson is recalled. Grows on strong reviews and shrinks
  /// on weak ones, stretching or compressing the interval ladder so difficult
  /// material comes back sooner than easy material at the same ladder step.
  final double easeFactor;
  final int intervalDays;

  /// How many times this lesson has been failed and sent back down the ladder.
  final int lapses;

  bool isDue(DateTime now) => !nextReview.isAfter(now);

  ReviewItem copyWith({
    DateTime? nextReview,
    DateTime? lastReviewed,
    int? reviewCount,
    double? easeFactor,
    int? intervalDays,
    int? lapses,
  }) {
    return ReviewItem(
      lessonId: lessonId,
      nextReview: nextReview ?? this.nextReview,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      lapses: lapses ?? this.lapses,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lessonId': lessonId,
      'nextReview': nextReview.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
      'reviewCount': reviewCount,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'lapses': lapses,
    };
  }

  factory ReviewItem.fromMap(Map<String, dynamic> map) {
    return ReviewItem(
      lessonId: map['lessonId'] as String,
      nextReview: DateTime.parse(map['nextReview'] as String),
      lastReviewed: map['lastReviewed'] == null
          ? null
          : DateTime.parse(map['lastReviewed'] as String),
      reviewCount: map['reviewCount'] as int,
      easeFactor: (map['easeFactor'] as num).toDouble(),
      intervalDays: map['intervalDays'] as int,
      // Absent in schedules saved before lapse tracking existed.
      lapses: (map['lapses'] as int?) ?? 0,
    );
  }
}
