import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../audio/providers/audio_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../../review/providers/review_providers.dart';
import '../models/practice_result.dart';
import '../models/practice_statistics.dart';
import '../repositories/hive_practice_repository.dart';
import '../repositories/practice_repository.dart';
import '../services/practice_generator.dart';
import '../services/practice_service.dart';
import '../services/practice_statistics_service.dart';

final practiceRepositoryProvider = Provider<PracticeRepository>(
  (Ref ref) => const HivePracticeRepository(),
);

final practiceGeneratorProvider = Provider<PracticeGenerator>(
  (Ref ref) => PracticeGenerator(
    audioRepository: ref.watch(audioRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
    reviewRepository: ref.watch(reviewRepositoryProvider),
    practiceRepository: ref.watch(practiceRepositoryProvider),
  ),
);

final practiceServiceProvider = ChangeNotifierProvider<PracticeService>(
  (Ref ref) => PracticeService(
    generator: ref.watch(practiceGeneratorProvider),
    repository: ref.watch(practiceRepositoryProvider),
  ),
);

final practiceStatisticsServiceProvider = Provider<PracticeStatisticsService>(
  (Ref ref) => PracticeStatisticsService(ref.watch(practiceRepositoryProvider)),
);

final practiceStatisticsProvider = FutureProvider<PracticeStatistics>((
  Ref ref,
) async {
  ref.watch(practiceServiceProvider);
  final PracticeStatisticsService service = ref.watch(
    practiceStatisticsServiceProvider,
  );
  return service.getStatistics();
});

final practiceResultsProvider = FutureProvider<List<PracticeResult>>((
  Ref ref,
) async {
  ref.watch(practiceServiceProvider);
  final PracticeRepository repository = ref.watch(practiceRepositoryProvider);
  return repository.getAllResults();
});

final listeningModeAvailableProvider = FutureProvider<bool>((Ref ref) async {
  final PracticeGenerator generator = ref.watch(practiceGeneratorProvider);
  return generator.isListeningModeAvailable();
});
