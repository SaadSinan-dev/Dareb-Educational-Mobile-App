import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/home/data/api_home_repository.dart';

void main() {
  test(
    'public home content maps observed media, subjects, and stats',
    () async {
      final adapter = _Adapter({
        '/api/home-page/index?perPage=10': _payload({
          'sliders': [
            {
              'id': 3,
              'link': 'https://example.test/promo',
              'image': 'https://example.test/3.png',
            },
          ],
          'news': [
            {
              'id': 4,
              'link': 'https://example.test/news',
              'image': 'https://example.test/4.png',
            },
          ],
          'subjects': [_subject],
          'courses': [
            {'id': 5},
          ],
          'notification_unread': 2,
          'completion_rate': 25,
          'subject_count': 1,
        }),
      });
      final client = ApiClient(baseUrl: 'https://example.test/api');
      client.dio.httpClientAdapter = adapter;

      final home = await ApiHomeRepository(client).getHome();
      expect(home.sliders.single.id, '3');
      expect(home.news.single.destinationUrl, 'https://example.test/news');
      expect(home.subjects.single.name, 'History');
      expect(home.featuredCourseIds, ['5']);
      expect(home.completionRate, 25);
      expect(home.unreadNotifications, 2);
      expect(adapter.requests.single.method, 'GET');
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    },
  );

  test('search uses verified query and maps observed exam records', () async {
    final adapter = _Adapter({
      '/api/home-page/search?perPage=10&text=History': _payload({
        'subjects': [_subject],
        'exams': [
          {
            'id': 1,
            'title': 'Observed exam',
            'questions': [],
            'questions_count': 10,
          },
        ],
        'dailyActivities': [
          {
            'id': 1,
            'title': 'Observed exam',
            'questions': [],
            'questions_count': 10,
          },
          {
            'id': 1,
            'title': 'Observed exam',
            'questions': [],
            'questions_count': 10,
          },
        ],
      }),
    });
    final client = ApiClient(baseUrl: 'https://example.test/api');
    client.dio.httpClientAdapter = adapter;

    final result = await ApiHomeRepository(client).search(' History ');
    expect(result.subjects.single.id, '5');
    expect(result.exams.single.id, '1');
    expect(result.activities.length, 2);
    expect(adapter.requests.single.uri.queryParameters['text'], 'History');
  });

  test('malformed home envelope fails with application error', () async {
    final adapter = _Adapter({
      '/api/home-page/index?perPage=10': _payload({
        'sliders': 'private-server-value',
      }),
    });
    final client = ApiClient(baseUrl: 'https://example.test/api');
    client.dio.httpClientAdapter = adapter;
    await expectLater(
      ApiHomeRepository(client).getHome(),
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

const _subject = {
  'id': 5,
  'name': 'History',
  'is_free': true,
  'is_subscription': false,
  'image': 'https://example.test/history.png',
};

Map<String, Object?> _payload(Object data) => {
  'message': 'Success',
  'data': data,
};

class _Adapter implements HttpClientAdapter {
  _Adapter(this.responses);
  final Map<String, Object?> responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.uri.path}?${options.uri.query}';
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
