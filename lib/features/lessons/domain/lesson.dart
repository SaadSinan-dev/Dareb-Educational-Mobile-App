import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/assessments/domain/assessment.dart';

class RemoteComment {
  const RemoteComment({required this.id, required this.text, this.author});
  final String id, text;
  final String? author;
}

class RemoteLesson {
  const RemoteLesson({
    required this.id,
    required this.title,
    required this.kind,
    required this.semesterId,
    required this.isAttended,
    required this.hasAccess,
    this.videoUrl,
    this.drive360,
    this.drive720,
    this.fileUrl,
    this.exam,
  });
  final String id, title, semesterId;
  final LessonKind kind;
  final bool isAttended, hasAccess;
  final String? videoUrl, drive360, drive720, fileUrl;
  final RemoteAssessment? exam;
}
