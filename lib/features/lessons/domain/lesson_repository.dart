import 'package:tamkeen2/features/lessons/domain/lesson.dart';

abstract interface class LessonRepository {
  Future<RemoteLesson> lesson(String id);
  Future<Uri> resolveVideo(RemoteLesson lesson, {bool highQuality = false});
  Future<void> attendLesson(String id);
  Future<void> lastAttended(String semesterId);
  Future<List<RemoteComment>> comments(String lessonId);
  Future<void> addComment(String lessonId, String text);
}
