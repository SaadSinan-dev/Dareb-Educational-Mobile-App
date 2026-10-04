import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/courses/data/course_data_source.dart';
import 'package:tamkeen2/features/courses/data/course_repository_impl.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';

void main() {
  test('catalog uses the verified paginate and details requests', () async {
    final adapter = _RoutingAdapter({
      '/api/courses/paginate?page=1&perPage=10': _payload([
        {'id': 5},
        {'id': 15},
      ]),
      '/api/courses/details?subject_id=5': _payload(
        _courseDetails(
          id: 5,
          name: 'Subject five',
          courseName: 'Course five',
          semesters: [
            {
              'id': 13,
              'is_free': true,
              'is_subscription': false,
              'lessions': [
                _lesson(25, 'Assessment', 3),
                _lesson(26, 'Document', 1, time: '10:02:32'),
                _lesson(27, 'Video', 2, time: '17:13:26'),
              ],
            },
          ],
        ),
      ),
      '/api/courses/details?subject_id=15': _payload(
        _courseDetails(id: 15, name: 'History', courseName: '', semesters: []),
      ),
    });
    final client = ApiClient(baseUrl: 'https://example.test/api');
    client.dio.httpClientAdapter = adapter;
    final source = ApiCourseDataSource(client);
    final courses = await CourseRepositoryImpl(source).getCourses();

    expect(courses, hasLength(2));
    expect(courses.first.id, '5');
    expect(courses.first.title, 'Course five');
    expect(courses.first.category, 'Subject five');
    expect(courses.first.teacher, 'Teacher');
    expect(courses.first.price, 54);
    expect(courses.first.lessons.map((lesson) => lesson.kind), [
      LessonKind.exam,
      LessonKind.document,
      LessonKind.video,
    ]);
    expect(courses.first.lessons[1].id, '26');
    expect(courses.first.lessons[1].semesterId, '13');
    expect(courses.first.lessons[1].semesterIsFree, isTrue);
    expect(courses.first.lessons[1].durationText, '10:02:32');
    expect(courses.first.lessons[1].minutes, 0);
    expect(courses.last.title, 'History');
    expect(courses.last.lessons, isEmpty);
    expect(adapter.requests.map((request) => request.uri.toString()), [
      'https://example.test/api/courses/paginate?page=1&perPage=10',
      'https://example.test/api/courses/details?subject_id=5',
      'https://example.test/api/courses/details?subject_id=15',
    ]);
    expect(
      adapter.requests.every(
        (request) =>
            request.method == 'GET' &&
            !request.headers.containsKey('Authorization'),
      ),
      isTrue,
    );
  });

  test('pagination forwards page and perPage exactly', () async {
    final adapter = _RoutingAdapter({
      '/api/courses/paginate?page=2&perPage=7': _payload([]),
    });
    final client = ApiClient(baseUrl: 'https://example.test/api');
    client.dio.httpClientAdapter = adapter;
    final page = await ApiCourseDataSource(
      client,
    ).readCoursePage(page: 2, perPage: 7);
    expect(page, isEmpty);
    expect(adapter.requests.single.uri.query, 'page=2&perPage=7');
  });

  test(
    'subjects all, paginate, and detail parse their observed envelopes',
    () async {
      final subject = {
        'id': 5,
        'name': 'Subject five',
        'is_free': false,
        'image': 'https://example.test/image.png',
        'is_subscription': true,
      };
      final adapter = _RoutingAdapter({
        '/api/subjects/all': _payload([subject]),
        '/api/subjects/paginate?page=2&perPage=7': _payload([subject]),
        '/api/subjects/details?id=5': _payload({
          'content': subject,
          'exams': [],
          'dailyActivities': [],
        }),
      });
      final client = ApiClient(baseUrl: 'https://example.test/api');
      client.dio.httpClientAdapter = adapter;
      final repository = CourseRepositoryImpl(ApiCourseDataSource(client));

      final all = await repository.getAllSubjects();
      final page = await repository.getSubjectPage(page: 2, perPage: 7);
      final details = await repository.getSubjectDetails('5');
      expect(all.single.name, 'Subject five');
      expect(page.single.id, '5');
      expect(details.isSubscribed, isTrue);
      expect(details.imageUrl, 'https://example.test/image.png');
      expect(adapter.requests.map((request) => request.uri.path), [
        '/api/subjects/all',
        '/api/subjects/paginate',
        '/api/subjects/details',
      ]);
    },
  );

  test('malformed catalog details fail without exposing server data', () async {
    final adapter = _RoutingAdapter({
      '/api/courses/details?subject_id=5': _payload({
        'id': 5,
        'name': 'server-private-detail',
        'semesters': 'unexpected',
      }),
    });
    final client = ApiClient(baseUrl: 'https://example.test/api');
    client.dio.httpClientAdapter = adapter;
    await expectLater(
      ApiCourseDataSource(client).readCourseDetails('5'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.message,
          'message',
          'استجاب الخادم ببيانات غير متوقعة. يرجى المحاولة لاحقاً.',
        ),
      ),
    );
  });
}

Map<String, Object?> _payload(Object data) => {
  'message': 'Success',
  'data': data,
};

Map<String, Object?> _courseDetails({
  required int id,
  required String name,
  required String courseName,
  required List<Map<String, Object?>> semesters,
}) => {
  'id': id,
  'name': name,
  'is_free': false,
  'course_name': courseName,
  'text': 'Description',
  'professor': 'Teacher',
  'price': 54,
  'image': 'https://example.test/course.png',
  'points_count': 0,
  'is_subscription': false,
  'semesters': semesters,
};

Map<String, Object?> _lesson(
  int id,
  String title,
  int typeId, {
  String? time,
}) => {
  'id': id,
  'name': title,
  'is_free': true,
  'order': id,
  'type': {'id': typeId, 'name': 'Type'},
  'time': time,
  'is_subscription': false,
};

class _RoutingAdapter implements HttpClientAdapter {
  _RoutingAdapter(this.responses);

  final Map<String, Object?> responses;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key =
        '${options.uri.path}${options.uri.hasQuery ? '?${options.uri.query}' : ''}';
    if (!responses.containsKey(key)) {
      throw StateError('Unexpected request: $key');
    }
    return ResponseBody.fromString(
      jsonEncode(responses[key]),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
