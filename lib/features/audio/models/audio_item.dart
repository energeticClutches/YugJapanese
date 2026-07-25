/// The kind of audio an [AudioItem] represents. Kept small on purpose;
/// add new values here (e.g. `sentence`) rather than branching on strings.
enum AudioType { character, word }

/// A resolved, playable piece of pronunciation audio bundled with the app.
///
/// Generic across scripts: [script] is the same content identifier used
/// throughout the app ('hiragana', 'katakana', 'kanji', and later any
/// vocabulary content), so no script-specific audio logic is needed.
class AudioItem {
  const AudioItem({
    required this.id,
    required this.assetPath,
    required this.type,
    required this.script,
  });

  final String id;
  final String assetPath;
  final AudioType type;
  final String script;
}
