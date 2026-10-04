import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';

void main() {
  test('late 401 for an older token cannot revoke a newer login', () async {
    String? authorization = 'Bearer old-token';
    final client = ApiClient(
      authorizationHeaderProvider: () async => authorization,
      onUnauthorized: (_) => authorization = null,
    );
    final adapter = _DelayedUnauthorizedAdapter();
    client.dio.httpClientAdapter = adapter;
    final request = expectLater(
      client.request<Object?>('profile/get'),
      throwsA(isA<AppFailure>()),
    );
    await adapter.started.future;
    authorization = 'Bearer new-token';
    adapter.release.complete();
    await request;
    expect(authorization, 'Bearer new-token');
  });

  test('401 for the current token still revokes the session', () async {
    String? authorization = 'Bearer rejected-token';
    final client = ApiClient(
      authorizationHeaderProvider: () async => authorization,
      onUnauthorized: (_) => authorization = null,
    );
    client.dio.httpClientAdapter = _ResponseAdapter(401);
    await expectLater(
      client.request<Object?>('profile/get'),
      throwsA(isA<AppFailure>()),
    );
    expect(authorization, isNull);
  });
  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.badCertificate,
    DioExceptionType.unknown,
  ]) {
    test('$type becomes a safe user-facing failure', () async {
      final client = ApiClient();
      client.dio.httpClientAdapter = _FailureAdapter(type);
      await expectLater(
        client.request<Object?>('transport-test'),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.message,
            'message',
            isNot(contains('secret-transport-detail')),
          ),
        ),
      );
    });
  }

  test(
    'cancelled requests never reach transport or invalidate the session',
    () async {
      var unauthorized = false;
      final client = ApiClient(
        onUnauthorized: (_) {
          unauthorized = true;
        },
      );
      final adapter = _ResponseAdapter(200);
      client.dio.httpClientAdapter = adapter;
      final cancellation = CancelToken()..cancel('secret-cancel-detail');
      await expectLater(
        client.request<Object?>('transport-test', cancelToken: cancellation),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.message,
            'message',
            isNot(contains('secret-cancel-detail')),
          ),
        ),
      );
      expect(adapter.request, isNull);
      expect(unauthorized, isFalse);
    },
  );

  test(
    'awaits asynchronous session invalidation and maps its errors safely',
    () async {
      var completed = false;
      final client = ApiClient(
        onUnauthorized: (_) async {
          await Future<void>.delayed(Duration.zero);
          completed = true;
          throw StateError('secret-session-detail');
        },
      );
      client.dio.httpClientAdapter = _ResponseAdapter(401);
      await expectLater(
        client.request<Object?>('transport-test'),
        throwsA(isA<AppFailure>()),
      );
      expect(completed, isTrue);
    },
  );

  test(
    'reads current authorization on every request and removes it after logout',
    () async {
      String? authorization = 'VerifiedScheme first-token';
      final client = ApiClient(
        authorizationHeaderProvider: () async => authorization,
      );
      final adapter = _ResponseAdapter(200);
      client.dio.httpClientAdapter = adapter;
      await client.request<Object?>('transport-test');
      expect(
        adapter.request!.headers['Authorization'],
        'VerifiedScheme first-token',
      );
      authorization = 'VerifiedScheme renewed-token';
      await client.request<Object?>('transport-test');
      expect(
        adapter.request!.headers['Authorization'],
        'VerifiedScheme renewed-token',
      );
      authorization = null;
      await client.request<Object?>('transport-test');
      expect(adapter.request!.headers.containsKey('Authorization'), isFalse);
    },
  );

  test(
    'authorization lookup failure is safe and prevents the network request',
    () async {
      final client = ApiClient(
        authorizationHeaderProvider: () =>
            throw StateError('secret-storage-detail'),
      );
      final adapter = _ResponseAdapter(200);
      client.dio.httpClientAdapter = adapter;
      await expectLater(
        client.request<Object?>('transport-test'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.message,
            'message',
            'حدث خطأ غير متوقع في التطبيق. يرجى المحاولة مجدداً.',
          ),
        ),
      );
      expect(adapter.request, isNull);
    },
  );

  test(
    'direct transport access cannot send credentials to another origin',
    () async {
      var credentialReads = 0;
      final client = ApiClient(
        authorizationHeaderProvider: () {
          credentialReads++;
          return 'VerifiedScheme token';
        },
      );
      final adapter = _ResponseAdapter(200);
      client.dio.httpClientAdapter = adapter;
      await expectLater(
        client.dio.get<Object?>('https://outside.test/private'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.request, isNull);
      expect(credentialReads, 0);
    },
  );

  test(
    'invalid authorization header prevents transport without leaking credentials',
    () async {
      final client = ApiClient(
        authorizationHeaderProvider: () =>
            'VerifiedScheme secret\r\nInjected: true',
      );
      final adapter = _ResponseAdapter(200);
      client.dio.httpClientAdapter = adapter;
      await expectLater(
        client.request<Object?>('transport-test'),
        throwsA(isA<AppFailure>()),
      );
      expect(adapter.request, isNull);
    },
  );

  test(
    'session callback failure cannot replace safe unauthorized error',
    () async {
      final client = ApiClient(
        onUnauthorized: (_) => throw StateError('secret-session-detail'),
      );
      client.dio.httpClientAdapter = _ResponseAdapter(401);
      await expectLater(
        client.request<Object?>('transport-test'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.statusCode,
            'status',
            401,
          ),
        ),
      );
    },
  );

  for (final path in [
    'https://outside.test/account',
    '//outside.test/account',
    '../account',
    'courses/../../account',
    '%2e%2e/account',
    'courses/%2F..%2Faccount',
  ]) {
    test('rejects path outside configured API boundary: $path', () async {
      final client = ApiClient(baseUrl: 'https://example.test/prefix/api');
      final adapter = _ResponseAdapter(200);
      client.dio.httpClientAdapter = adapter;
      await expectLater(
        client.request<Object?>(path),
        throwsA(isA<AppFailure>()),
      );
      expect(adapter.request, isNull);
    });
  }

  test('does not automatically forward a request through redirects', () async {
    final client = ApiClient();
    final adapter = _ResponseAdapter(302);
    client.dio.httpClientAdapter = adapter;
    await expectLater(
      client.request<Object?>('transport-test'),
      throwsA(isA<AppFailure>()),
    );
    expect(adapter.request!.followRedirects, isFalse);
  });

  test(
    'transport preserves configured API prefix and sends no invented auth',
    () async {
      final client = ApiClient(baseUrl: 'https://example.test/prefix/api');
      final adapter = _ResponseAdapter(200);
      client.dio.httpClientAdapter = adapter;
      await client.request<Object?>('transport-test');
      expect(
        adapter.request!.uri.toString(),
        'https://example.test/prefix/api/transport-test',
      );
      expect(adapter.request!.headers.containsKey('Authorization'), isFalse);
    },
  );

  test('unauthorized notifies session owner and emits safe failure', () async {
    var unauthorized = 0;
    final client = ApiClient(onUnauthorized: (_) => unauthorized++);
    client.dio.httpClientAdapter = _ResponseAdapter(401);
    await expectLater(
      client.request<Object?>('transport-test'),
      throwsA(isA<AppFailure>()),
    );
    expect(unauthorized, 1);
  });

  for (final status in [400, 403, 404, 409, 422, 429, 500, 503]) {
    test('HTTP $status never exposes server exception body', () async {
      final client = ApiClient();
      client.dio.httpClientAdapter = _ResponseAdapter(status);
      try {
        await client.request<Object?>('transport-test');
        fail('Failure expected');
      } on AppFailure catch (error) {
        expect(error.message, isNot(contains('secret-server-trace')));
        expect(error.statusCode, status);
      }
    });
  }

  for (final (status, message) in [
    (500, 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.'),
    (502, 'تعذر الوصول إلى خادم الخدمة. يرجى المحاولة لاحقاً.'),
    (503, 'الخدمة متوقفة مؤقتاً. يرجى المحاولة لاحقاً.'),
  ]) {
    test('HTTP $status has a distinct safe message', () async {
      final client = ApiClient(baseUrl: 'https://example.test/api');
      client.dio.httpClientAdapter = _ResponseAdapter(status);
      await expectLater(
        client.request<Object?>('transport-test'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.message,
            'message',
            message,
          ),
        ),
      );
    });
  }

  test(
    'backend response remains available internally without leaking to UI',
    () async {
      final client = ApiClient(baseUrl: 'https://example.test/api');
      client.dio.httpClientAdapter = _ResponseAdapter(422);
      try {
        await client.request<Object?>('transport-test');
        fail('Expected validation failure');
      } on AppFailure catch (failure) {
        expect((failure as dynamic).backendBody, {
          'message': 'secret-server-trace',
        });
        expect(failure.message, isNot(contains('secret-server-trace')));
        expect(failure.toString(), isNot(contains('secret-server-trace')));
      }
    },
  );

  test('malformed JSON has a distinct safe response error', () async {
    final client = ApiClient(baseUrl: 'https://example.test/api');
    client.dio.httpClientAdapter = _MalformedAdapter();
    await expectLater(
      client.request<Object?>('transport-test'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.message,
          'message',
          'استجاب الخادم ببيانات غير متوقعة. يرجى المحاولة لاحقاً.',
        ),
      ),
    );
  });

  test(
    'debug failure log keeps route metadata but excludes sensitive values',
    () async {
      final output = <String>[];
      final previous = debugPrint;
      debugPrint = (message, {wrapWidth}) => output.add(message ?? '');
      addTearDown(() => debugPrint = previous);
      final client = ApiClient(
        baseUrl: 'https://example.test/api',
        authorizationHeaderProvider: () => 'Bearer secret-token',
      );
      client.dio.httpClientAdapter = _ResponseAdapter(422);
      await expectLater(
        client.request<Object?>(
          'transport-test',
          method: 'POST',
          data: FormData.fromMap({
            'phone': 'secret-phone',
            'verification_code': 'secret-code',
            'fcm_token': 'secret-fcm',
          }),
        ),
        throwsA(isA<AppFailure>()),
      );
      final log = output.join('\n');
      expect(log, contains('POST /api/transport-test'));
      expect(log, contains('status=422'));
      expect(log, contains('verification_code'));
      for (final sensitive in [
        'secret-phone',
        'secret-code',
        'secret-fcm',
        'secret-token',
        'secret-server-trace',
      ]) {
        expect(log, isNot(contains(sensitive)));
      }
    },
  );

  for (final (cause, expected) in [
    (
      SocketException(
        'Network is unreachable',
        osError: OSError('Network is unreachable', 101),
      ),
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة ثم حاول مجدداً.',
    ),
    (
      SocketException('Failed host lookup: training.example'),
      'تعذر العثور على خادم الخدمة. تحقق من الشبكة وحاول مجدداً.',
    ),
  ]) {
    test('connection failure distinguishes ${cause.message}', () async {
      final client = ApiClient(baseUrl: 'https://example.test/api');
      client.dio.httpClientAdapter = _FailureAdapter(
        DioExceptionType.connectionError,
        cause: cause,
      );
      await expectLater(
        client.request<Object?>('transport-test'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.message,
            'message',
            expected,
          ),
        ),
      );
    });
  }
}

class _ResponseAdapter implements HttpClientAdapter {
  _ResponseAdapter(this.status);
  final int status;
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '{"message":"secret-server-trace"}',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _DelayedUnauthorizedAdapter implements HttpClientAdapter {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    started.complete();
    await release.future;
    return ResponseBody.fromString('{}', 401);
  }

  @override
  void close({bool force = false}) {}
}

class _FailureAdapter implements HttpClientAdapter {
  _FailureAdapter(this.type, {this.cause});
  final DioExceptionType type;
  final Object? cause;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: type,
      error: cause ?? 'secret-transport-detail',
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MalformedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{malformed',
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}
