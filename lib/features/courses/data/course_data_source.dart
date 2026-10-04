import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/courses/data/course_model.dart';

abstract interface class CourseDataSource {
  Future<List<CourseModel>> readCourses();
  Future<List<CourseModel>> readCoursePage({
    required int page,
    required int perPage,
  });
  Future<CourseModel> readCourseDetails(String subjectId);
  Future<List<SubjectModel>> readAllSubjects();
  Future<List<SubjectModel>> readSubjectPage({
    required int page,
    required int perPage,
  });
  Future<SubjectModel> readSubjectDetails(String id);
  Future<List<QuizQuestion>> readQuestions(String courseId);
}

/// Live endpoints verified against the collection's configured API host.
/// Course details are loaded with each catalog record so lessons are real.
class ApiCourseDataSource implements CourseDataSource {
  const ApiCourseDataSource(this.client);
  final ApiClient client;

  @override
  Future<List<CourseModel>> readCourses() async {
    const perPage = 10;
    final courses = <CourseModel>[];
    final seenIds = <String>{};
    for (var page = 1; ; page++) {
      final batch = await readCoursePage(page: page, perPage: perPage);
      for (final course in batch) {
        if (!seenIds.add(course.id)) {
          throw const AppFailure(AppCopy.unexpectedResponse);
        }
        courses.add(course);
      }
      if (batch.length < perPage) break;
    }
    return List.unmodifiable(courses);
  }

  @override
  Future<List<CourseModel>> readCoursePage({
    required int page,
    required int perPage,
  }) async {
    _validPage(page, perPage);
    final entries = await _listData(
      'courses/paginate',
      query: {'page': page, 'perPage': perPage},
    );
    final ids = <String>[];
    for (final entry in entries) {
      final id = _id(entry);
      if (ids.contains(id)) {
        throw const AppFailure(AppCopy.unexpectedResponse);
      }
      ids.add(id);
    }
    final details = await Future.wait(
      entries.map((entry) async {
        try {
          return await readCourseDetails(_id(entry));
        } on AppFailure catch (error) {
          // One broken detail endpoint must not destroy a valid catalog/search
          // field. Preserve the actual summary and expose its detail failure.
          if (error.statusCode == null || error.statusCode! < 500) rethrow;
          return CourseModel.fromApiDetails({
            ...entry,
            'semesters': <Object?>[],
          }, detailsError: error.message);
        }
      }),
    );
    return List.unmodifiable(details);
  }

  @override
  Future<CourseModel> readCourseDetails(String subjectId) async {
    final id = _positiveId(subjectId);
    final data = await _objectData(
      'courses/details',
      query: {'subject_id': id},
    );
    try {
      final course = CourseModel.fromApiDetails(data);
      if (course.id != subjectId) throw const FormatException('ID mismatch');
      return course;
    } on FormatException {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: data);
    }
  }

  @override
  Future<List<SubjectModel>> readAllSubjects() async =>
      _subjects(await _listData('subjects/all'));

  @override
  Future<List<SubjectModel>> readSubjectPage({
    required int page,
    required int perPage,
  }) async {
    _validPage(page, perPage);
    return _subjects(
      await _listData(
        'subjects/paginate',
        query: {'page': page, 'perPage': perPage},
      ),
    );
  }

  @override
  Future<SubjectModel> readSubjectDetails(String id) async {
    final parsedId = _positiveId(id);
    final data = await _objectData('subjects/details', query: {'id': parsedId});
    try {
      final content = data['content'];
      if (content is! Map<String, dynamic>) throw const FormatException();
      final subject = SubjectModel.fromApiJson(content);
      if (subject.id != id) throw const FormatException('ID mismatch');
      return subject;
    } on FormatException {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: data);
    }
  }

  @override
  Future<List<QuizQuestion>> readQuestions(String courseId) async =>
      throw const AppFailure.unavailable();

  Future<List<Map<String, dynamic>>> _listData(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await client.request<Object?>(
      path,
      queryParameters: query,
    );
    final root = response.data;
    if (root is! Map<String, dynamic> || root['data'] is! List) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: root);
    }
    final result = <Map<String, dynamic>>[];
    for (final item in root['data'] as List) {
      if (item is! Map<String, dynamic>) {
        throw AppFailure(AppCopy.unexpectedResponse, backendBody: item);
      }
      result.add(item);
    }
    return result;
  }

  Future<Map<String, dynamic>> _objectData(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await client.request<Object?>(
      path,
      queryParameters: query,
    );
    final root = response.data;
    if (root is! Map<String, dynamic> ||
        root['data'] is! Map<String, dynamic>) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: root);
    }
    return root['data'] as Map<String, dynamic>;
  }

  static List<SubjectModel> _subjects(List<Map<String, dynamic>> data) {
    try {
      return List.unmodifiable(data.map(SubjectModel.fromApiJson));
    } on FormatException {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: data);
    }
  }

  static String _id(Map<String, dynamic> record) {
    final value = record['id'];
    if (value is! int || value <= 0) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: record);
    }
    return value.toString();
  }

  static int _positiveId(String raw) {
    final value = int.tryParse(raw);
    if (value == null || value <= 0 || value.toString() != raw) {
      throw const AppFailure(AppCopy.badRequest);
    }
    return value;
  }

  static void _validPage(int page, int perPage) {
    if (page <= 0 || perPage <= 0) {
      throw const AppFailure(AppCopy.badRequest);
    }
  }
}

class UnavailableCourseDataSource implements CourseDataSource {
  const UnavailableCourseDataSource();
  @override
  Future<List<CourseModel>> readCourses() async =>
      throw const AppFailure.unavailable();
  @override
  Future<List<CourseModel>> readCoursePage({
    required int page,
    required int perPage,
  }) async => throw const AppFailure.unavailable();
  @override
  Future<CourseModel> readCourseDetails(String subjectId) async =>
      throw const AppFailure.unavailable();
  @override
  Future<List<SubjectModel>> readAllSubjects() async =>
      throw const AppFailure.unavailable();
  @override
  Future<List<SubjectModel>> readSubjectPage({
    required int page,
    required int perPage,
  }) async => throw const AppFailure.unavailable();
  @override
  Future<SubjectModel> readSubjectDetails(String id) async =>
      throw const AppFailure.unavailable();
  @override
  Future<List<QuizQuestion>> readQuestions(String courseId) async =>
      throw const AppFailure.unavailable();
}

/// Offline demonstration until a real backend contract is supplied.
class MockCourseDataSource implements CourseDataSource {
  const MockCourseDataSource();

  @override
  Future<List<CourseModel>> readCoursePage({
    required int page,
    required int perPage,
  }) async => throw const AppFailure.unavailable();
  @override
  Future<CourseModel> readCourseDetails(String subjectId) async =>
      throw const AppFailure.unavailable();
  @override
  Future<List<SubjectModel>> readAllSubjects() async =>
      throw const AppFailure.unavailable();
  @override
  Future<List<SubjectModel>> readSubjectPage({
    required int page,
    required int perPage,
  }) async => throw const AppFailure.unavailable();
  @override
  Future<SubjectModel> readSubjectDetails(String id) async =>
      throw const AppFailure.unavailable();

  @override
  Future<List<CourseModel>> readCourses() async => const [
    CourseModel(
      id: 'math',
      title: AppCopy.mathCourse,
      category: AppCopy.mathematicsSubject,
      teacher: AppCopy.teacherOmarNabulsi,
      description: AppCopy.mathCourseDescription,
      lessonTitles: [
        AppCopy.introductionToStatisticsFour,
        AppCopy.introductionToAlgebraFour,
        AppCopy.naturalNumbers,
        AppCopy.arithmeticOperations,
        AppCopy.fractions,
        AppCopy.equations,
        AppCopy.geometry,
        AppCopy.statistics,
        AppCopy.practicalApplications,
        AppCopy.chapterReview,
        AppCopy.comprehensiveExercises,
        AppCopy.finalExam,
      ],
      isFree: true,
      price: 0,
      accent: 0xFFE2F5F4,
      points: 22,
    ),
    CourseModel(
      id: 'science',
      title: AppCopy.generalScience,
      category: AppCopy.scienceSubject,
      teacher: AppCopy.teacherSaraAli,
      description: AppCopy.scienceCourseDescription,
      lessonTitles: [
        AppCopy.introductionToScience,
        AppCopy.matterAndEnergy,
        AppCopy.experimentAndPractice,
      ],
      isFree: true,
      price: 0,
      accent: 0xFFEAE8F9,
    ),
    CourseModel(
      id: 'arabic',
      title: AppCopy.arabicLanguage,
      category: AppCopy.languagesCategory,
      teacher: AppCopy.teacherMaryamKhaled,
      description: AppCopy.arabicCourseDescription,
      lessonTitles: [
        AppCopy.lettersAndWords,
        AppCopy.readingLesson,
        AppCopy.writingLesson,
      ],
      isFree: false,
      price: 49,
      accent: 0xFFFFF0D9,
    ),
    CourseModel(
      id: 'english',
      title: AppCopy.englishLanguage,
      category: AppCopy.languagesCategory,
      teacher: AppCopy.teacherMohammedHassan,
      description: AppCopy.englishCourseDescription,
      lessonTitles: [
        AppCopy.alphabetLesson,
        AppCopy.vocabularyLesson,
        AppCopy.conversationLesson,
      ],
      isFree: false,
      price: 59,
      accent: 0xFFE4F0FA,
    ),
  ];

  @override
  Future<List<QuizQuestion>> readQuestions(String courseId) async =>
      switch (courseId) {
        'math' => const [
          QuizQuestion(
            title: AppCopy.positiveValueQuestion,
            expression: '2x² − 8 = 0',
            answers: ['2', '3', '4'],
            correctIndex: 0,
          ),
          QuizQuestion(
            title: AppCopy.sumQuestion,
            expression: '7 + 5 = ?',
            answers: ['12', '10', '14'],
            correctIndex: 0,
          ),
        ],
        'science' => const [
          QuizQuestion(
            title: AppCopy.redPlanetQuestion,
            answers: [
              AppCopy.planetMars,
              AppCopy.planetJupiter,
              AppCopy.planetEarth,
            ],
            correctIndex: 0,
          ),
          QuizQuestion(
            title: AppCopy.renewableEnergyQuestion,
            answers: [AppCopy.sunAnswer, AppCopy.coalAnswer, AppCopy.oilAnswer],
            correctIndex: 0,
          ),
        ],
        'arabic' => const [
          QuizQuestion(
            title: AppCopy.bookPluralQuestion,
            answers: [
              AppCopy.booksAnswer,
              AppCopy.writerAnswer,
              AppCopy.libraryAnswer,
            ],
            correctIndex: 0,
          ),
          QuizQuestion(
            title: AppCopy.verbQuestion,
            answers: [
              AppCopy.readsAnswer,
              AppCopy.bookAnswer,
              AppCopy.schoolInstitutionOption,
            ],
            correctIndex: 0,
          ),
        ],
        'english' => const [
          QuizQuestion(
            title: AppCopy.bookMeaningQuestion,
            answers: [
              AppCopy.bookAnswer,
              AppCopy.penAnswer,
              AppCopy.doorAnswer,
            ],
            correctIndex: 0,
          ),
          QuizQuestion(
            title: AppCopy.englishGreetingQuestion,
            answers: ['Hello', 'Table', 'Blue'],
            correctIndex: 0,
          ),
        ],
        _ => throw const AppFailure(AppCopy.quizUnavailableMessage),
      };
}
