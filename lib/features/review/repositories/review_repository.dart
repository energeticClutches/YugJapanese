import '../models/review_item.dart';

abstract class ReviewRepository {
  Future<List<ReviewItem>> getAllReviews();

  Future<ReviewItem?> getReview(String lessonId);

  Future<void> saveReview(ReviewItem review);
}
