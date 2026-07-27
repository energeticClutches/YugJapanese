import 'dart:ui';

/// One reference stroke of a character, as an ordered polyline in a
/// normalized 0–1 coordinate space (origin top-left).
///
/// The source data is KanjiVG's per-stroke SVG paths; the cubic Béziers
/// were flattened to polylines and normalized offline (see `CREDITS.md`
/// and `assets/data/stroke_data.json`) so nothing has to parse SVG at
/// runtime. Call [scaledTo] to map a stroke onto an actual canvas.
class StrokeTemplate {
  const StrokeTemplate({required this.points});

  /// Points in 0–1 space, in the order the stroke is written.
  final List<Offset> points;

  /// This stroke's points mapped onto a canvas of [size].
  List<Offset> scaledTo(Size size) {
    return <Offset>[
      for (final Offset p in points)
        Offset(p.dx * size.width, p.dy * size.height),
    ];
  }

  static StrokeTemplate fromJson(List<dynamic> json) {
    return StrokeTemplate(
      points: <Offset>[
        for (final dynamic pair in json)
          Offset(
            ((pair as List<dynamic>)[0] as num).toDouble(),
            (pair[1] as num).toDouble(),
          ),
      ],
    );
  }
}

/// The full ordered set of reference strokes for a single character.
class CharacterStrokes {
  const CharacterStrokes({required this.symbol, required this.strokes});

  final String symbol;
  final List<StrokeTemplate> strokes;

  int get strokeCount => strokes.length;

  static CharacterStrokes fromJson(String symbol, List<dynamic> json) {
    return CharacterStrokes(
      symbol: symbol,
      strokes: <StrokeTemplate>[
        for (final dynamic stroke in json)
          StrokeTemplate.fromJson(stroke as List<dynamic>),
      ],
    );
  }
}
