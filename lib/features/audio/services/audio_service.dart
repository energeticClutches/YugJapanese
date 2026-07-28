import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/audio_item.dart';
import '../repositories/audio_repository.dart';

enum AudioPlaybackStatus { idle, loading, playing, error }

/// Which [AudioItem.id] the current [AudioPlaybackStatus] applies to, so
/// widgets for other characters don't show a stale loading/playing state.
class AudioPlaybackState {
  const AudioPlaybackState({
    this.status = AudioPlaybackStatus.idle,
    this.currentId,
  });

  final AudioPlaybackStatus status;
  final String? currentId;

  bool isFor(String id) => currentId == id;
}

/// Plays pronunciation audio for any script, driven entirely by the
/// (id, assetPath, script) triple already carried on every learning item —
/// no script-specific playback logic.
class AudioService extends ChangeNotifier {
  AudioService(this._repository) {
    _completeSubscription = _player.onPlayerComplete.listen(
      (_) => _setState(const AudioPlaybackState()),
    );
  }

  final AudioRepository _repository;
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<void> _completeSubscription;

  AudioPlaybackState _state = const AudioPlaybackState();
  AudioPlaybackState get state => _state;

  Future<void> play({
    required String id,
    required String assetPath,
    required String script,
    AudioType type = AudioType.character,
  }) async {
    _setState(
      AudioPlaybackState(status: AudioPlaybackStatus.loading, currentId: id),
    );

    final AudioItem? item = await _repository.resolveAudio(
      id: id,
      assetPath: assetPath,
      script: script,
      type: type,
    );
    if (item == null) {
      _setState(
        AudioPlaybackState(status: AudioPlaybackStatus.error, currentId: id),
      );
      return;
    }

    try {
      await _player.stop();
      await _player.play(AssetSource(_stripAssetsPrefix(item.assetPath)));
      _setState(
        AudioPlaybackState(status: AudioPlaybackStatus.playing, currentId: id),
      );
    } catch (_) {
      _setState(
        AudioPlaybackState(status: AudioPlaybackStatus.error, currentId: id),
      );
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Ignore: stopping is best-effort and should never surface an error.
    }
    _setState(const AudioPlaybackState());
  }

  /// Extension point for a future playback-volume setting.
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  String _stripAssetsPrefix(String assetPath) {
    return assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;
  }

  void _setState(AudioPlaybackState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _completeSubscription.cancel();
    _player.dispose();
    super.dispose();
  }
}
