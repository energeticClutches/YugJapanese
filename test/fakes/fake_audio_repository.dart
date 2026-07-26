import 'package:japanese_learning/features/audio/models/audio_item.dart';
import 'package:japanese_learning/features/audio/repositories/audio_repository.dart';

/// Always reports no audio available — keeps generator/service tests
/// focused on non-audio logic without depending on real asset resolution.
class FakeAudioRepository implements AudioRepository {
  @override
  Future<AudioItem?> resolveAudio({
    required String id,
    required String assetPath,
    required String script,
    AudioType type = AudioType.character,
  }) async {
    return null;
  }
}
