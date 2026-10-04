import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';
import 'package:tamkeen2/features/auth/data/live_auth_repository.dart';
import 'package:tamkeen2/features/auth/data/postman_auth_data_source.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';

class _MemorySessions implements AuthSessionStore {
  AuthSession? session;
  String installationId = 'test-installation-id';

  @override
  Future<AuthSession?> readSession() async => session;

  @override
  Future<void> saveSession(AuthSession value) async => session = value;

  @override
  Future<bool> clearSession({String? expectedToken}) async {
    if (expectedToken != null && session?.token != expectedToken) return false;
    session = null;
    return true;
  }

  @override
  Future<String> deviceId() async => installationId;
}

class _Capture {
  final requests = <RequestOptions>[];
  Object? response = <String, Object?>{};
  int status = 200;
  Completer<void>? release;
  Completer<void>? seen;

  void attach(ApiClient client) {
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests.add(options);
          seen?.complete();
          await release?.future;
          if (status >= 400) {
            handler.reject(
              DioException.badResponse(
                statusCode: status,
                requestOptions: options,
                response: Response<Object?>(
                  requestOptions: options,
                  data: response,
                  statusCode: status,
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: response,
              statusCode: status,
            ),
          );
        },
      ),
    );
  }
}

void main() {
  late _MemorySessions sessions;
  late _Capture publicCapture;
  late _Capture privateCapture;
  late PostmanAuthDataSource source;

  setUp(() {
    sessions = _MemorySessions();
    publicCapture = _Capture();
    privateCapture = _Capture();
    final publicClient = ApiClient(baseUrl: 'https://example.test/api');
    final privateClient = ApiClient(
      baseUrl: 'https://example.test/api',
      authorizationHeaderProvider: () async {
        final token = (await sessions.readSession())?.token;
        return token == null ? null : 'Bearer $token';
      },
    );
    publicCapture.attach(publicClient);
    privateCapture.attach(privateClient);
    source = PostmanAuthDataSource(
      publicClient: publicClient,
      authenticatedClient: privateClient,
    );
  });

  test(
    'login and resend send their documented multipart fields only',
    () async {
      await source.login('0500000000');
      await source.resend('0500000000');

      expect(publicCapture.requests, hasLength(2));
      expect(publicCapture.requests[0].method, 'POST');
      expect(publicCapture.requests[0].uri.path, '/api/auth/login');
      expect(
        Map.fromEntries((publicCapture.requests[0].data as FormData).fields),
        {'phone': '0500000000'},
      );
      expect(publicCapture.requests[1].method, 'POST');
      expect(publicCapture.requests[1].uri.path, '/api/auth/resend');
      expect(
        Map.fromEntries((publicCapture.requests[1].data as FormData).fields),
        {'phone': '0500000000'},
      );
      expect(privateCapture.requests, isEmpty);
    },
  );

  test('activation sends exact fields and reads only data.token', () async {
    publicCapture.response = <String, Object?>{
      'data': <String, Object?>{'token': 'verified-token'},
    };
    final token = await source.activate(
      phone: '0500000000',
      code: '1234',
      fcmToken: 'real-token-from-provider',
      deviceId: 'test-installation-id',
    );

    expect(token, 'verified-token');
    final request = publicCapture.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/auth/active');
    expect(Map.fromEntries((request.data as FormData).fields), {
      'phone': '0500000000',
      'verification_code': '1234',
      'fcm_token': 'real-token-from-provider',
      'device_id': 'test-installation-id',
    });
    expect(request.headers.containsKey('Authorization'), isFalse);
  });

  test(
    'activation omits optional FCM field when no token is configured',
    () async {
      publicCapture.response = <String, Object?>{
        'data': <String, Object?>{'token': 'verified-token'},
      };
      final token = await source.activate(
        phone: '0500000000',
        code: '1111',
        deviceId: 'test-installation-id',
      );
      expect(token, 'verified-token');
      expect(
        Map.fromEntries(
          (publicCapture.requests.single.data as FormData).fields,
        ),
        {
          'phone': '0500000000',
          'verification_code': '1111',
          'device_id': 'test-installation-id',
        },
      );
    },
  );

  test(
    'activation without documented token field cannot authenticate',
    () async {
      publicCapture.response = <String, Object?>{'token': 'wrong-location'};
      await expectLater(
        source.activate(
          phone: '0500000000',
          code: '1234',
          fcmToken: 'real-token-from-provider',
          deviceId: 'test-installation-id',
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.message,
            'message',
            'استجاب الخادم ببيانات غير متوقعة. يرجى المحاولة لاحقاً.',
          ),
        ),
      );
    },
  );

  test('logout and account delete use bearer and documented methods', () async {
    sessions.session = const AuthSession(
      phone: '0500000000',
      token: 'verified-token',
    );
    await source.logout();
    await source.deleteAccount();

    expect(privateCapture.requests, hasLength(2));
    expect(privateCapture.requests[0].method, 'GET');
    expect(privateCapture.requests[0].uri.path, '/api/auth/logout');
    expect(privateCapture.requests[1].method, 'POST');
    expect(privateCapture.requests[1].uri.path, '/api/auth/delete');
    for (final request in privateCapture.requests) {
      expect(request.headers['Authorization'], 'Bearer verified-token');
    }
  });

  test(
    'school lookup sends the selected type and governorate to the real route',
    () async {
      sessions.session = const AuthSession(
        phone: '15555550113',
        token: 'verified-token',
      );
      privateCapture.response = <String, Object?>{
        'data': [
          {'id': 27, 'name': 'Backend school'},
        ],
      };

      final schools = await source.schools(type: 1, governorate: 'damascus');

      expect(schools, hasLength(1));
      expect(schools.single.id, 27);
      expect(schools.single.name, 'Backend school');
      final request = privateCapture.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/schools/all');
      expect(request.queryParameters, {'type': 1, 'governorate': 'damascus'});
      expect(request.headers['Authorization'], 'Bearer verified-token');
    },
  );

  test('repository activates without optional FCM token', () async {
    publicCapture.response = <String, Object?>{
      'data': <String, Object?>{'token': 'verified-token'},
    };
    final repository = LiveAuthRepository(source, sessions);
    final user = await repository.verifyCode('0500000000', '1111');
    expect(user.phone, '0500000000');
    expect(publicCapture.requests, hasLength(1));
    expect(sessions.session?.token, 'verified-token');
  });

  test(
    'profile completion sends verified multipart fields with bearer token',
    () async {
      sessions.session = const AuthSession(
        phone: '15555215554',
        token: 'verified-token',
      );
      privateCapture.response = <String, Object?>{
        'data': <String, Object?>{'id': 1},
      };
      final repository = LiveAuthRepository(source, sessions);
      final draft = const RegistrationDraft(
        gender: Gender.female,
        age: 22,
        institutionType: InstitutionType.school,
        studyType: StudyType.science,
        firstName: 'QA',
        lastName: 'Tester',
        email: 'qa@example.invalid',
        phone: '15555215554',
        school: 'Test school',
        schoolId: 7,
        branchId: 1,
        referralSource: ReferralSource.friend,
        acceptedTerms: true,
      );
      final user = await repository.register(draft);
      expect(user.phone, '15555215554');
      expect(privateCapture.requests, hasLength(2));
      final request = privateCapture.requests.first;
      expect(request.uri.path, '/api/users/edit');
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer verified-token');
      expect(Map.fromEntries((request.data as FormData).fields), {
        'f_name': 'QA',
        'l_name': 'Tester',
        'email': 'qa@example.invalid',
        'school_id': '7',
        'know_about_app': '3',
        'gender': '0',
        'age': '22',
        'branch_id': '1',
      });
      expect(privateCapture.requests.last.uri.path, '/api/profile/get');
    },
  );

  test('login and resend work without an optional FCM token', () async {
    final repository = LiveAuthRepository(source, sessions);
    await repository.requestCode('0500000000');
    await repository.resendCode('0500000000');
    expect(publicCapture.requests, hasLength(2));
  });

  test(
    'verified activation persists token and restores local session identity',
    () async {
      publicCapture.response = <String, Object?>{
        'data': <String, Object?>{'token': 'verified-token'},
      };
      final repository = LiveAuthRepository(
        source,
        sessions,
        fcmTokenProvider: () async => 'live-fcm-token',
      );
      final user = await repository.verifyCode('0500000000', '1234');
      expect(user.phone, '0500000000');
      expect(user.id, startsWith('local:'));
      expect(user.id, isNot(contains('0500000000')));
      expect(sessions.session?.token, 'verified-token');
      privateCapture.response = <String, Object?>{
        'data': <String, Object?>{'branch_id': 1},
      };
      expect((await repository.restoreSession())?.id, user.id);
    },
  );

  for (final token in ['expired-token', 'invalid-token']) {
    test('$token is cleared after a 401 without a startup error', () async {
      sessions.session = AuthSession(phone: '0500000000', token: token);
      privateCapture.status = 401;
      final repository = LiveAuthRepository(source, sessions);
      expect(await repository.restoreSession(), isNull);
      expect(sessions.session, isNull);
    });
  }
  test('missing token skips the profile request', () async {
    expect(await LiveAuthRepository(source, sessions).restoreSession(), isNull);
    expect(privateCapture.requests, isEmpty);
  });
  for (final data in [null, <Object?>[], 'temporarily unavailable', false]) {
    test('malformed profile data $data cannot require registration', () async {
      sessions.session = const AuthSession(
        phone: '0500000000',
        token: 'valid-token',
      );
      privateCapture.response = {'data': data};
      await expectLater(
        LiveAuthRepository(source, sessions).restoreSession(),
        throwsA(isA<AppFailure>()),
      );
      expect(sessions.session?.token, 'valid-token');
    });
  }

  test(
    'only explicit backend profile requirement resumes registration',
    () async {
      sessions.session = const AuthSession(
        phone: '0500000000',
        token: 'valid-token',
      );
      privateCapture.status = 400;
      privateCapture.response = {'message': 'المستخدم ليس لديه فرع'};
      final user = await LiveAuthRepository(source, sessions).restoreSession();
      expect(user?.profileComplete, isFalse);
      expect(sessions.session?.token, 'valid-token');
    },
  );
  test('server failure preserves credentials for startup retry', () async {
    sessions.session = const AuthSession(
      phone: '0500000000',
      token: 'valid-token',
    );
    privateCapture.status = 503;
    await expectLater(
      LiveAuthRepository(source, sessions).restoreSession(),
      throwsA(isA<AppFailure>()),
    );
    expect(sessions.session, isNotNull);
  });

  test('old restoration rejection cannot delete a replacement token', () async {
    sessions.session = const AuthSession(
      phone: '0500000000',
      token: 'old-token',
    );
    privateCapture.status = 401;
    privateCapture.seen = Completer<void>();
    privateCapture.release = Completer<void>();
    final restoration = expectLater(
      LiveAuthRepository(source, sessions).restoreSession(),
      throwsA(isA<AppFailure>()),
    );
    await privateCapture.seen!.future;
    sessions.session = const AuthSession(
      phone: '0500000000',
      token: 'new-token',
    );
    privateCapture.release!.complete();
    await restoration;
    expect(sessions.session?.token, 'new-token');
  });

  test('logout clears credentials after server request', () async {
    sessions.session = const AuthSession(
      phone: '0500000000',
      token: 'verified-token',
    );
    final repository = LiveAuthRepository(source, sessions);
    await repository.logout();
    expect(privateCapture.requests, hasLength(1));
    expect(sessions.session, isNull);
    expect(await repository.restoreSession(), isNull);
  });

  test(
    'logout waits for pending activation before clearing its token',
    () async {
      publicCapture.response = <String, Object?>{
        'data': <String, Object?>{'token': 'verified-token'},
      };
      publicCapture.seen = Completer<void>();
      publicCapture.release = Completer<void>();
      final repository = LiveAuthRepository(
        source,
        sessions,
        fcmTokenProvider: () async => 'live-fcm-token',
      );
      final activation = repository.verifyCode('0500000000', '1234');
      await publicCapture.seen!.future;
      final logout = repository.logout();
      publicCapture.release!.complete();
      await Future.wait([activation, logout]);

      expect(sessions.session, isNull);
      expect(
        privateCapture.requests.single.headers['Authorization'],
        'Bearer verified-token',
      );
    },
  );
}
