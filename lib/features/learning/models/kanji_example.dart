/// A single example word demonstrating a kanji in context. Generic enough to
/// be reused as a standalone vocabulary entry once vocabulary lessons exist.
class KanjiExample {
  const KanjiExample({
    required this.word,
    required this.reading,
    required this.meaning,
  });

  final String word;
  final String reading;
  final String meaning;

  factory KanjiExample.fromJson(Map<String, dynamic> json) {
    return KanjiExample(
      word: json['word'] as String,
      reading: json['reading'] as String,
      meaning: json['meaning'] as String,
    );
  }
}
