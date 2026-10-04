import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/subject.dart';

/// Typed local demonstration record, not a claimed server response.
class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.teacher,
    required this.description,
    required this.lessonTitles,
    required this.isFree,
    required this.price,
    required this.accent,
    this.points = 0,
    this.imageUrl,
    this.isSubscribed = false,
    this.lessonModels,
    this.detailsError,
    this.lessonCount,
  });

  /// Parsed from the observed `courses/details?subject_id=` response. A
  /// catalog entry is resolved to details before it is shown as a course.
  factory CourseModel.fromApiDetails(
    Map<String, dynamic> json, {
    String? detailsError,
  }) {
    final name = _string(json, 'name');
    final courseName = _string(json, 'course_name');
    final semesters = _list(json, 'semesters');
    final lessons = <LessonModel>[];
    for (final semesterValue in semesters) {
      final semester = _object(semesterValue);
      final semesterId = _integer(semester, 'id').toString();
      final semesterIsFree = _boolean(semester, 'is_free');
      final semesterIsSubscribed = _boolean(semester, 'is_subscription');
      for (final lessonValue in _list(semester, 'lessions')) {
        lessons.add(
          LessonModel.fromApiJson(
            _object(lessonValue),
            semesterId: semesterId,
            semesterIsFree: semesterIsFree,
            semesterIsSubscribed: semesterIsSubscribed,
          ),
        );
      }
    }
    return CourseModel(
      id: _integer(json, 'id').toString(),
      title: courseName.trim().isEmpty ? name : courseName,
      category: name,
      teacher: _string(json, 'professor'),
      description: _string(json, 'text'),
      lessonTitles: const [],
      lessonModels: List.unmodifiable(lessons),
      isFree: _boolean(json, 'is_free'),
      price: _integer(json, 'price'),
      accent: 0xFFE2F5F4,
      points: _integer(json, 'points_count'),
      imageUrl: _optionalString(json, 'image'),
      isSubscribed: _boolean(json, 'is_subscription'),
      detailsError: detailsError,
      lessonCount: json['lessions_count'] is int
          ? json['lessions_count'] as int
          : null,
    );
  }

  final String id;
  final String title;
  final String category;
  final String teacher;
  final String description;
  final List<String> lessonTitles;
  final bool isFree;
  final int price;
  final int accent;
  final int points;
  final String? imageUrl;
  final bool isSubscribed;
  final List<LessonModel>? lessonModels;
  final String? detailsError;
  final int? lessonCount;

  Course toEntity() => Course(
    id: id,
    title: title,
    category: category,
    teacher: teacher,
    description: description,
    lessons: List<Lesson>.unmodifiable(
      lessonModels == null
          ? [
              for (var i = 0; i < lessonTitles.length; i++)
                Lesson(
                  title: lessonTitles[i],
                  minutes: id == 'math' && i == 0 ? 22 : 12,
                  kind: i == 1 ? LessonKind.document : LessonKind.video,
                  pages: i == 1 ? 40 : 0,
                ),
            ]
          : lessonModels!.map((lesson) => lesson.toEntity()),
    ),
    isFree: isFree,
    price: price,
    accent: accent,
    points: points,
    imageUrl: imageUrl,
    isSubscribed: isSubscribed,
    detailsError: detailsError,
    lessonCount: lessonCount,
  );
}

class LessonModel {
  const LessonModel({
    required this.id,
    required this.semesterId,
    required this.semesterIsFree,
    required this.semesterIsSubscribed,
    required this.title,
    required this.kind,
    required this.isFree,
    required this.isSubscribed,
    this.durationText,
  });

  factory LessonModel.fromApiJson(
    Map<String, dynamic> json, {
    required String semesterId,
    required bool semesterIsFree,
    required bool semesterIsSubscribed,
  }) {
    final type = _object(json['type']);
    final kind = switch (_integer(type, 'id')) {
      1 => LessonKind.document,
      2 => LessonKind.video,
      3 => LessonKind.exam,
      _ => throw const FormatException('Unknown lesson type'),
    };
    return LessonModel(
      id: _integer(json, 'id').toString(),
      semesterId: semesterId,
      semesterIsFree: semesterIsFree,
      semesterIsSubscribed: semesterIsSubscribed,
      title: _string(json, 'name'),
      kind: kind,
      isFree: _boolean(json, 'is_free'),
      isSubscribed: _boolean(json, 'is_subscription'),
      durationText: _optionalString(json, 'time'),
    );
  }

  final String id;
  final String semesterId;
  final bool semesterIsFree;
  final bool semesterIsSubscribed;
  final String title;
  final LessonKind kind;
  final bool isFree;
  final bool isSubscribed;
  final String? durationText;

  Lesson toEntity() => Lesson(
    id: id,
    semesterId: semesterId,
    semesterIsFree: semesterIsFree,
    semesterIsSubscribed: semesterIsSubscribed,
    title: title,
    kind: kind,
    isFree: isFree,
    isSubscribed: isSubscribed,
    durationText: durationText,
    // The server's `time` format is not documented as a duration in minutes.
    minutes: 0,
  );
}

class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.name,
    required this.isFree,
    required this.isSubscribed,
    this.imageUrl,
  });

  factory SubjectModel.fromApiJson(Map<String, dynamic> json) => SubjectModel(
    id: _integer(json, 'id').toString(),
    name: _string(json, 'name'),
    isFree: _boolean(json, 'is_free'),
    isSubscribed: _boolean(json, 'is_subscription'),
    imageUrl: _optionalString(json, 'image'),
  );

  final String id;
  final String name;
  final bool isFree;
  final bool isSubscribed;
  final String? imageUrl;

  Subject toEntity() => Subject(
    id: id,
    name: name,
    isFree: isFree,
    isSubscribed: isSubscribed,
    imageUrl: imageUrl,
  );
}

Map<String, dynamic> _object(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('Expected object');
}

List<dynamic> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) return value;
  throw const FormatException('Expected list');
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw const FormatException('Expected string');
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null || value == '') return null;
  if (value is String) return value;
  throw const FormatException('Expected optional string');
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw const FormatException('Expected integer');
}

bool _boolean(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw const FormatException('Expected boolean');
}
