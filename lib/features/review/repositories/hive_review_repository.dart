import 'package:hive/hive.dart';

import '../models/review_item.dart';
import 'review_repository.dart';

class HiveReviewRepository implements ReviewRepository {
  const HiveReviewRepository();

  static const String boxName = 'review_schedule';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<List<ReviewItem>> getAllReviews() async {
    return _box.values
        .whereType<Map>()
        .map(
          (Map value) => ReviewItem.fromMap(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
  }

  @override
  Future<ReviewItem?> getReview(String lessonId) async {
    final value = _box.get(lessonId);
    if (value is! Map) {
      return null;
    }
    return ReviewItem.fromMap(Map<String, dynamic>.from(value));
  }

  @override
  Future<void> saveReview(ReviewItem review) {
    return _box.put(review.lessonId, review.toMap());
  }
}
