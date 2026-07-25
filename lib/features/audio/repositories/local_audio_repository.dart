import 'package:flutter/services.dart' show rootBundle;

import '../models/audio_item.dart';
import 'audio_repository.dart';

/// Resolves audio against the assets actually bundled with the app,
/// verifying existence with [rootBundle] rather than assuming every path
/// referenced by lesson data has a matching file. This is what lets
/// Hiragana/Katakana/Kanji reference audio paths ahead of the recordings
/// existing: missing files simply resolve to `null`.
class LocalAudioRepository implements AudioRepository {
  LocalAudioRepository();

  final Map<String, bool> _existsCache = <String, bool>{};

  @override
  Future<AudioItem?> resolveAudio({
    required String id,
    required String assetPath,
    required String script,
    AudioType type = AudioType.character,
  }) async {
    if (assetPath.isEmpty || !await _assetExists(assetPath)) {
      return null;
    }
    return AudioItem(id: id, assetPath: assetPath, type: type, script: script);
  }

  Future<bool> _assetExists(String assetPath) async {
    final bool? cached = _existsCache[assetPath];
    if (cached != null) {
      return cached;
    }
    bool exists;
    try {
      await rootBundle.load(assetPath);
      exists = true;
    } catch (_) {
      exists = false;
    }
    _existsCache[assetPath] = exists;
    return exists;
  }
}
