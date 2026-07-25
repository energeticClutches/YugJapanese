import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../repositories/audio_repository.dart';
import '../repositories/local_audio_repository.dart';
import '../services/audio_service.dart';

final audioRepositoryProvider = Provider<AudioRepository>(
  (Ref ref) => LocalAudioRepository(),
);

final audioServiceProvider = ChangeNotifierProvider<AudioService>(
  (Ref ref) => AudioService(ref.watch(audioRepositoryProvider)),
);

final currentPlaybackStateProvider = Provider<AudioPlaybackState>(
  (Ref ref) => ref.watch(audioServiceProvider).state,
);
