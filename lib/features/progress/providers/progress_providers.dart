import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../repositories/hive_progress_repository.dart';
import '../repositories/progress_repository.dart';
import '../services/progress_controller.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (Ref ref) => const HiveProgressRepository(),
);

final progressControllerProvider = ChangeNotifierProvider<ProgressController>(
  (Ref ref) => ProgressController(ref.watch(progressRepositoryProvider)),
);
