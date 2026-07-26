import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/audio_item.dart';
import '../providers/audio_providers.dart';
import '../services/audio_service.dart';
import 'playback_indicator.dart';

/// A tap-to-play pronunciation control. Resolves whether audio actually
/// exists for (id, assetPath) and disables itself with an explanatory label
/// when it doesn't, when sound is off in settings, or while resolving —
/// callers never need to check availability themselves.
class AudioButton extends ConsumerStatefulWidget {
  const AudioButton({
    super.key,
    required this.id,
    required this.assetPath,
    required this.script,
    this.type = AudioType.character,
  });

  final String id;
  final String assetPath;
  final String script;
  final AudioType type;

  @override
  ConsumerState<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends ConsumerState<AudioButton> {
  late Future<AudioItem?> _resolveFuture = _resolve();

  Future<AudioItem?> _resolve() {
    if (widget.assetPath.isEmpty) {
      return Future<AudioItem?>.value(null);
    }
    return ref.read(audioRepositoryProvider).resolveAudio(
          id: widget.id,
          assetPath: widget.assetPath,
          script: widget.script,
          type: widget.type,
        );
  }

  @override
  void didUpdateWidget(covariant AudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.assetPath != widget.assetPath) {
      _resolveFuture = _resolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool soundEnabled =
        ref.watch(currentSettingsProvider).settings.soundEnabled;
    final AudioPlaybackState playback = ref.watch(currentPlaybackStateProvider);
    final bool isThisPlaying =
        playback.isFor(widget.id) && playback.status == AudioPlaybackStatus.playing;
    final bool isThisLoading =
        playback.isFor(widget.id) && playback.status == AudioPlaybackStatus.loading;
    final bool isThisError =
        playback.isFor(widget.id) && playback.status == AudioPlaybackStatus.error;

    return FutureBuilder<AudioItem?>(
      future: _resolveFuture,
      builder: (BuildContext context, AsyncSnapshot<AudioItem?> snapshot) {
        final bool resolved = snapshot.connectionState == ConnectionState.done;
        final bool available = snapshot.data != null;
        final bool enabled = soundEnabled && resolved && available;
        final String label = _label(
          resolved: resolved,
          available: available,
          soundEnabled: soundEnabled,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              onPressed: enabled
                  ? () => ref.read(audioServiceProvider).play(
                        id: widget.id,
                        assetPath: widget.assetPath,
                        script: widget.script,
                        type: widget.type,
                      )
                  : null,
              tooltip: label,
              icon: PlaybackIndicator(
                isLoading: isThisLoading,
                isPlaying: isThisPlaying,
                isError: isThisError,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
      },
    );
  }

  String _label({
    required bool resolved,
    required bool available,
    required bool soundEnabled,
  }) {
    if (!resolved) {
      return 'Checking audio…';
    }
    if (!available) {
      return 'Audio not available';
    }
    if (!soundEnabled) {
      return 'Sound is off';
    }
    return 'Play Pronunciation';
  }
}
