import '../models/audio_item.dart';

abstract class AudioRepository {
  /// Resolves [assetPath] to a playable [AudioItem], or `null` if the audio
  /// isn't bundled with the app yet. Never throws.
  Future<AudioItem?> resolveAudio({
    required String id,
    required String assetPath,
    required String script,
    AudioType type = AudioType.character,
  });
}
