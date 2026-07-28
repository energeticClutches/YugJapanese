import '../../../repositories/lesson_repository.dart';

class ContentSource {
  const ContentSource({required this.contentId, required this.repository});

  final String contentId;
  final LessonRepository repository;
}
