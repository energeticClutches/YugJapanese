import '../features/learning/models/kanji_example.dart';

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
    this.secondaryReadings = const <String>[],
    this.kunReadings = const <String>[],
    this.radical,
    this.grade,
    this.jlptLevel,
    this.examples = const <KanjiExample>[],
    this.notes,
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

  /// Optional richer metadata used by Kanji (and left empty/null by
  /// Hiragana and Katakana). Kept generic so a future vocabulary item could
  /// populate the same fields.
  final List<String> secondaryReadings;
  final List<String> kunReadings;
  final String? radical;
  final int? grade;
  final String? jlptLevel;
  final List<KanjiExample> examples;
  final String? notes;

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
      secondaryReadings:
          (json['secondaryReadings'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const <String>[],
      kunReadings:
          (json['kunReadings'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const <String>[],
      radical: json['radical'] as String?,
      grade: json['grade'] as int?,
      jlptLevel: json['jlptLevel'] as String?,
      examples:
          (json['examples'] as List<dynamic>?)
              ?.map(
                (dynamic e) => KanjiExample.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <KanjiExample>[],
      notes: json['notes'] as String?,
    );
  }
}
