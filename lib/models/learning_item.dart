class LearningItem {
  const LearningItem({
    required this.id,
    required this.symbol,
    required this.primaryReading,
    this.secondaryReading,
    required this.meaning,
    required this.strokeCount,
    required this.lessonNumber,
    required this.audioAsset,
    required this.strokeAsset,
    this.metadata,
  });

  final String id;
  final String symbol;
  final String primaryReading;
  final String? secondaryReading;
  final String meaning;
  final int strokeCount;
  final int lessonNumber;
  final String audioAsset;
  final String strokeAsset;
  final Map<String, dynamic>? metadata;

  factory LearningItem.fromJson(Map<String, dynamic> json) {
    return LearningItem(
      id: json['id'] as String,
      symbol: json['character'] as String,
      primaryReading: json['romaji'] as String,
      secondaryReading: json['secondaryReading'] as String?,
      meaning: json['englishName'] as String,
      strokeCount: json['strokeCount'] as int,
      lessonNumber: json['lessonNumber'] as int,
      audioAsset: json['audioAsset'] as String,
      strokeAsset: json['strokeAsset'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
