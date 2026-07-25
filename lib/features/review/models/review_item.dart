class ReviewItem {
  const ReviewItem({
    required this.lessonId,
    required this.nextReview,
    this.lastReviewed,
    required this.reviewCount,
    required this.easeFactor,
    required this.intervalDays,
  });

  /// Generic identifier for the reviewed lesson, e.g. "hiragana:1".
  final String lessonId;
  final DateTime nextReview;
  final DateTime? lastReviewed;
  final int reviewCount;

  /// Reserved for a future adaptive (SM-2 style) scheduler; unused by the
  /// current fixed-interval scheduler.
  final double easeFactor;
  final int intervalDays;

  bool isDue(DateTime now) => !nextReview.isAfter(now);

  ReviewItem copyWith({
    DateTime? nextReview,
    DateTime? lastReviewed,
    int? reviewCount,
    double? easeFactor,
    int? intervalDays,
  }) {
    return ReviewItem(
      lessonId: lessonId,
      nextReview: nextReview ?? this.nextReview,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
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
    );
  }
}
