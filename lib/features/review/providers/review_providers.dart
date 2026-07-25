import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review_item.dart';
import '../repositories/hive_review_repository.dart';
import '../repositories/review_repository.dart';
import '../services/review_scheduler.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (Ref ref) => const HiveReviewRepository(),
);

final reviewSchedulerProvider = Provider<ReviewScheduler>(
  (Ref ref) => ReviewScheduler(ref.watch(reviewRepositoryProvider)),
);

final dueReviewsProvider = FutureProvider<List<ReviewItem>>(
  (Ref ref) async {
    final ReviewScheduler scheduler = ref.watch(reviewSchedulerProvider);
    return scheduler.getDueReviews();
  },
);
