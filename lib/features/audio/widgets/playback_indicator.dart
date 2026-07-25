import 'package:flutter/material.dart';

/// The icon/spinner shown inside [AudioButton] (and reusable anywhere else
/// a compact playback-status glyph is needed) for a single playback state.
class PlaybackIndicator extends StatelessWidget {
  const PlaybackIndicator({
    super.key,
    this.isLoading = false,
    this.isPlaying = false,
    this.isError = false,
  });

  final bool isLoading;
  final bool isPlaying;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (isError) {
      return const Icon(Icons.error_outline);
    }
    return Icon(isPlaying ? Icons.volume_up : Icons.play_circle_outline);
  }
}
