class Course {
  const Course({
    required this.id,
    required this.title,
    required this.category,
    required this.teacher,
    required this.description,
    required this.lessons,
    required this.isFree,
    required this.price,
    required this.accent,
    this.points = 0,
    this.imageUrl,
    this.isSubscribed = false,
    this.detailsError,
    this.lessonCount,
  });

  final String id;
  final String title;
  final String category;
  final String teacher;
  final String description;
  final List<Lesson> lessons;
  final bool isFree;
  final int price;
  final int accent;
  final int points;

  /// The API's image field, when available. Preview records have no URL.
  final String? imageUrl;
  final bool isSubscribed;
  final String? detailsError;
  final int? lessonCount;
}

enum LessonKind { video, document, exam }

class Lesson {
  const Lesson({
    required this.title,
    required this.minutes,
    this.kind = LessonKind.video,
    this.pages = 0,
    this.id,
    this.semesterId,
    this.semesterIsFree = false,
    this.semesterIsSubscribed = false,
    this.isFree = false,
    this.isSubscribed = false,
    this.durationText,
  });
  final String title;
  final int minutes;
  final LessonKind kind;
  final int pages;
  final String? id;
  final String? semesterId;
  final bool semesterIsFree;
  final bool semesterIsSubscribed;
  final bool isFree;
  final bool isSubscribed;

  /// Uninterpreted API `time` value; the server has not documented its unit.
  final String? durationText;
}
