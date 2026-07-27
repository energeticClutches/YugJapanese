import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/stroke_template.dart';

/// Loads the bundled reference stroke data (see `CREDITS.md` — derived
/// from KanjiVG) and resolves it per character.
///
/// The whole file is ~290 KB, so it is decoded once on first use and then
/// cached for the life of the app. A character with no entry resolves to
/// `null` rather than throwing, mirroring how [LocalAudioRepository]
/// treats a missing recording: the writing UI degrades to free drawing
/// without a stroke guide instead of breaking the lesson.
class StrokeDataRepository {
  StrokeDataRepository({this.assetPath = 'assets/data/stroke_data.json'});

  final String assetPath;

  Map<String, CharacterStrokes>? _cache;
  Future<Map<String, CharacterStrokes>>? _inFlight;

  Future<Map<String, CharacterStrokes>> _load() {
    final Map<String, CharacterStrokes>? cached = _cache;
    if (cached != null) {
      return Future<Map<String, CharacterStrokes>>.value(cached);
    }
    // Several characters can request data during the same frame; share one
    // decode rather than parsing the asset once per caller.
    return _inFlight ??= _decode();
  }

  Future<Map<String, CharacterStrokes>> _decode() async {
    try {
      final String raw = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, dynamic> characters =
          decoded['characters'] as Map<String, dynamic>;

      final Map<String, CharacterStrokes> parsed = <String, CharacterStrokes>{};
      characters.forEach((String symbol, dynamic strokes) {
        parsed[symbol] =
            CharacterStrokes.fromJson(symbol, strokes as List<dynamic>);
      });
      _cache = parsed;
      return parsed;
    } catch (_) {
      // A missing or malformed bundle must not take the lesson down.
      _cache = <String, CharacterStrokes>{};
      return _cache!;
    } finally {
      _inFlight = null;
    }
  }

  /// Reference strokes for [symbol], or `null` when none are bundled.
  Future<CharacterStrokes?> strokesFor(String symbol) async {
    final Map<String, CharacterStrokes> all = await _load();
    return all[symbol];
  }
}
