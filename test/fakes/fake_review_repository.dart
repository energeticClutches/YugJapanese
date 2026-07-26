import 'package:japanese_learning/features/review/models/review_item.dart';
import 'package:japanese_learning/features/review/repositories/review_repository.dart';

/// Simple in-memory [ReviewRepository] for tests — no Hive involved.
class FakeReviewRepository implements ReviewRepository {
  final Map<String, ReviewItem> _store = <String, ReviewItem>{};

  @override
  Future<List<ReviewItem>> getAllReviews() async =>
      _store.values.toList(growable: false);

  @override
  Future<ReviewItem?> getReview(String lessonId) async => _store[lessonId];

  @override
  Future<void> saveReview(ReviewItem review) async {
    _store[review.lessonId] = review;
  }
}
