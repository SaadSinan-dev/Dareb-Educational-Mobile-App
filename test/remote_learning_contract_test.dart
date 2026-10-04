import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/assessments/data/api_assessment_repository.dart';
import 'package:tamkeen2/features/lessons/data/api_lesson_repository.dart';
import 'package:tamkeen2/features/assessments/presentation/exam_cubit.dart';

void main() {
  late ApiClient client;
  late _Adapter adapter;
  late ApiAssessmentRepository repository;
  late ApiLessonRepository lessons;
  setUp(() {
    client = ApiClient(
      baseUrl: 'https://example.test/api',
      authorizationHeaderProvider: () => 'Bearer qa-test',
    );
    adapter = _Adapter();
    client.dio.httpClientAdapter = adapter;
    repository = ApiAssessmentRepository(client);
    lessons = ApiLessonRepository(client);
  });
  test(
    'history reads both authenticated endpoints and empty collections',
    () async {
      adapter.response = {'data': []};
      expect(await repository.history(activities: false), isEmpty);
      expect(adapter.last!.path, 'exams/my');
      expect(adapter.last!.headers['Authorization'], 'Bearer qa-test');
      expect(await repository.history(activities: true), isEmpty);
      expect(adapter.last!.path, 'daily-activities/my');
    },
  );
  test('exam result maps the actual server counters and answers', () async {
    adapter.response = jsonDecode(
      File('test/fixtures/api/exam_result.json').readAsStringSync(),
    );
    final result = await repository.result('1');
    expect(result.id, '1');
    expect(result.questions.length, 10);
    expect(result.questions.first.answers.first.id, '1');
    expect(result.correctAnswers, isA<int>());
    expect(adapter.last!.queryParameters, {'id': 1});
  });
  test(
    'submission serializes repeated multipart answers_id[] fields',
    () async {
      adapter.response = {'data': null};
      await repository.submitAnswers(['2', '6']);
      expect(adapter.last!.path, 'exams/attend-exam');
      expect(adapter.last!.method, 'POST');
      expect(
        (adapter.last!.data as FormData).fields
            .map((e) => [e.key, e.value])
            .toList(),
        [
          ['answers_id[]', '2'],
          ['answers_id[]', '6'],
        ],
      );
      expect(adapter.multipart, contains('name="answers_id[]"'));
      expect(
        RegExp('name="answers_id\\[\\]"').allMatches(adapter.multipart).length,
        2,
      );
    },
  );
  test(
    'lesson reads actual URL and attendance requires successful backend writes',
    () async {
      adapter.response = jsonDecode(
        File('test/fixtures/api/lesson_details.json').readAsStringSync(),
      );
      final lesson = await lessons.lesson('9');
      expect(lesson.videoUrl, 'https://example.test/videos/lesson.mp4');
      adapter.response = {'data': null};
      await lessons.attendLesson('9');
      expect((adapter.last!.data as FormData).fields.single.key, 'lession_id');
      await lessons.lastAttended(lesson.semesterId);
      expect((adapter.last!.data as FormData).fields.single.key, 'semester_id');
    },
  );
  test(
    'duplicate exam submission is prevented including after result loading failure',
    () async {
      adapter.response = jsonDecode(
        File('test/fixtures/api/exam_result.json').readAsStringSync(),
      );
      final cubit = ExamCubit(repository);
      addTearDown(cubit.close);
      await cubit.load('1');
      for (final question in cubit.state.data!.questions) {
        cubit.select(question.id, question.answers.first.id);
      }
      adapter.blockPosts = true;
      final first = cubit.submit();
      final second = await cubit.submit();
      expect(second, isFalse);
      adapter.releasePost();
      await first;
      expect(adapter.postCount, 1);
      await cubit.submit();
      expect(adapter.postCount, 1);
    },
  );
}

class _Adapter implements HttpClientAdapter {
  Object? response;
  RequestOptions? last;
  String multipart = '';
  int postCount = 0;
  bool blockPosts = false;
  final _release = Completer<void>();
  void releasePost() => _release.complete();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    last = options;
    if (options.method == 'POST') {
      postCount++;
      if (stream != null) {
        multipart = utf8.decode(
          await stream.fold<List<int>>([], (all, part) => all..addAll(part)),
        );
      }
      if (blockPosts) await _release.future;
    }
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
