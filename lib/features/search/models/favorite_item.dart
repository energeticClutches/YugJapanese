class FavoriteItem {
  const FavoriteItem({
    required this.script,
    required this.itemId,
    required this.symbol,
    required this.createdAt,
  });

  final String script;
  final String itemId;
  final String symbol;
  final DateTime createdAt;

  /// Unique across all sources, e.g. "kanji:一".
  String get id => '$script:$itemId';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'script': script,
      'itemId': itemId,
      'symbol': symbol,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      script: map['script'] as String,
      itemId: map['itemId'] as String,
      symbol: map['symbol'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
