import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/account/data/live_account_repository.dart';
import 'package:tamkeen2/features/account/data/postman_account_data_source.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';

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
  late _Capture publicCapture;
  late _Capture privateCapture;
  late PostmanAccountDataSource source;

  setUp(() {
    publicCapture = _Capture();
    privateCapture = _Capture();
    final publicClient = ApiClient(baseUrl: 'https://example.test/api');
    final privateClient = ApiClient(
      baseUrl: 'https://example.test/api',
      authorizationHeaderProvider: () => 'Bearer test-token',
    );
    publicCapture.attach(publicClient);
    privateCapture.attach(privateClient);
    source = PostmanAccountDataSource(
      publicClient: publicClient,
      authenticatedClient: privateClient,
    );
  });

  test(
    'three public page routes parse their observed id/value envelope',
    () async {
      publicCapture.response = <String, Object?>{
        'message': 'الصفحات الموجودة',
        'data': <String, Object?>{'id': 2, 'value': 'الشروط<div>نص</div>'},
      };
      for (final kind in AccountPageKind.values) {
        final page = await source.loadPage(kind);
        expect(page.id, 2);
        expect(page.value, 'الشروط<div>نص</div>');
      }
      expect(publicCapture.requests.map((request) => request.uri.path), [
        '/api/pages/privacy-policy',
        '/api/pages/terms-conditions',
        '/api/pages/about-application',
      ]);
      expect(
        publicCapture.requests.every((request) => request.method == 'GET'),
        isTrue,
      );
      expect(
        publicCapture.requests.every(
          (request) => !request.headers.containsKey('Authorization'),
        ),
        isTrue,
      );
      expect(privateCapture.requests, isEmpty);
    },
  );

  test('page parsing fails closed if the observed fields disappear', () async {
    publicCapture.response = <String, Object?>{
      'data': <String, Object?>{'id': '2', 'content': 'unexpected'},
    };
    await expectLater(
      source.loadPage(AccountPageKind.termsConditions),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.message,
          'message',
          'استجاب الخادم ببيانات غير متوقعة. يرجى المحاولة لاحقاً.',
        ),
      ),
    );
  });

  test('gallery reads only verified album summary fields', () async {
    privateCapture.response = <String, Object?>{
      'message': 'المعرض الموجود',
      'data': <Object?>[
        <String, Object?>{
          'id': 8,
          'name': 'فتحـية العلامي',
          'images': <Object?>[],
        },
      ],
    };
    final albums = await source.loadGallerySummaries();
    expect(albums, hasLength(1));
    expect(albums.single.id, 8);
    expect(albums.single.name, 'فتحـية العلامي');
    expect(albums.single.imageCount, 0);
    expect(privateCapture.requests.single.uri.path, '/api/galleries/all');
    expect(privateCapture.requests.single.method, 'GET');
    expect(
      privateCapture.requests.single.headers['Authorization'],
      'Bearer test-token',
    );
  });

  test('gallery parsing rejects an unverified album shape', () async {
    privateCapture.response = <String, Object?>{
      'data': <Object?>[
        <String, Object?>{'id': 8, 'name': 'album'},
      ],
    };
    await expectLater(
      source.loadGallerySummaries(),
      throwsA(isA<AppFailure>()),
    );
  });

  test(
    'gallery retains backend URLs rather than just counting images',
    () async {
      privateCapture.response = {
        'data': [
          {
            'id': 8,
            'name': 'Album',
            'images': [
              'https://images.example.test/photo.png',
              {'id': 10, 'image': 'https://images.example.test/photo2.png'},
            ],
          },
        ],
      };
      final albums = await source.loadGallerySummaries();
      expect(albums.single.images, [
        'https://images.example.test/photo.png',
        'https://images.example.test/photo2.png',
      ]);
      expect(albums.single.imageCount, 2);
    },
  );

  test('an empty CMS value is not an unexpected response error', () async {
    publicCapture.response = {
      'data': {'id': 1, 'value': null},
    };
    final page = await source.loadPage(AccountPageKind.privacyPolicy);
    expect(page.value, isEmpty);
  });

  test('an absent CMS record produces the empty state', () async {
    publicCapture.response = {'data': null};
    expect(
      (await source.loadPage(AccountPageKind.privacyPolicy)).value,
      isEmpty,
    );
  });

  test(
    'gallery rejects non-web image URLs instead of silently replacing them',
    () async {
      for (final value in [
        'file:///private/photo.png',
        'javascript:alert(1)',
        {'id': 10},
      ]) {
        privateCapture.response = {
          'data': [
            {
              'id': 8,
              'name': 'Album',
              'images': [value],
            },
          ],
        };
        await expectLater(
          source.loadGallerySummaries(),
          throwsA(isA<AppFailure>()),
        );
      }
    },
  );

  test('public contact details parse observed email and phone', () async {
    publicCapture.response = <String, Object?>{
      'message': 'المعلومات الموجودة',
      'data': <String, Object?>{
        'email': 'support@example.test',
        'phone': '0993571184',
        'facebook': 'https://www.facebook.com',
      },
    };
    final info = await source.loadContactInfo();
    expect(info.email, 'support@example.test');
    expect(info.phone, '0993571184');
    expect(publicCapture.requests.single.uri.path, '/api/infos/all');
    expect(publicCapture.requests.single.method, 'GET');
    expect(
      publicCapture.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
    expect(privateCapture.requests, isEmpty);
  });

  test('completed profile loads verified name, school and points', () async {
    privateCapture.response = <String, Object?>{
      'data': <String, Object?>{
        'id': 42,
        'f_name': 'QA',
        'l_name': 'Registration',
        'school': <String, Object?>{
          'id': 7,
          'name': 'Test school',
          'governorate': 'damascus',
        },
        'points': 12,
        'image': 'https://example.test/avatar.png',
        'medals': 3,
        'package_count': 2,
      },
    };
    final account = await LiveAccountRepository(source).load('local:user');
    expect(account.profile?.displayName, 'QA Registration');
    expect(account.profile?.school, 'Test school');
    expect(account.profile?.schoolId, 7);
    expect(account.profile?.imageUrl, 'https://example.test/avatar.png');
    expect(account.summary?.points, 12);
    expect(account.summary?.courses, isNull);
    expect(privateCapture.requests.single.uri.path, '/api/profile/get');
    expect(
      privateCapture.requests.single.headers['Authorization'],
      'Bearer test-token',
    );
  });

  test('FAQ records parse verified id, question and answer fields', () async {
    privateCapture.response = <String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'id': 1,
          'question': 'How do courses work?',
          'answer': 'Open a course to see its lessons.',
        },
      ],
    };
    final faqs = await source.loadFaqs();
    expect(faqs.single.id, 1);
    expect(faqs.single.question, 'How do courses work?');
    expect(faqs.single.answer, 'Open a course to see its lessons.');
    expect(privateCapture.requests.single.uri.path, '/api/faqs/all');
    expect(
      privateCapture.requests.single.headers['Authorization'],
      'Bearer test-token',
    );
  });

  test(
    'profile update sends exact multipart fields with bearer auth',
    () async {
      privateCapture.response = <String, Object?>{
        'data': <String, Object?>{'id': 42},
      };
      await source.updateUser(
        const AccountProfile(
          firstName: 'QA',
          lastName: 'Updated',
          school: 'Test school',
          schoolId: 7,
        ),
      );
      final request = privateCapture.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/users/update');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(Map.fromEntries((request.data as FormData).fields), {
        'f_name': 'QA',
        'l_name': 'Updated',
        'school_id': '7',
      });
    },
  );

  test('profile image upload uses the verified multipart file field', () async {
    await source.updateImage(
      Uint8List.fromList([137, 80, 78, 71]),
      'avatar.png',
      'image/png',
    );
    final request = privateCapture.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/users/update-image');
    expect(request.headers['Authorization'], 'Bearer test-token');
    final form = request.data as FormData;
    expect(form.fields, isEmpty);
    expect(form.files.single.key, 'image');
    expect(form.files.single.value.filename, 'avatar.png');
    expect(form.files.single.value.contentType.toString(), 'image/png');
  });

  test(
    'profile parser fails closed when observed school shape changes',
    () async {
      privateCapture.response = <String, Object?>{
        'data': <String, Object?>{
          'f_name': 'QA',
          'l_name': 'Registration',
          'school': 'unexpected',
          'points': 12,
        },
      };
      await expectLater(source.loadAccountData(), throwsA(isA<AppFailure>()));
    },
  );

  test('protected request gateways use exact paths and query names', () async {
    await source.requestProfile();
    await source.requestPoints();
    await source.requestMedals(page: 2, perPage: 5);
    await source.requestCups();
    await source.requestNotifications();
    await source.requestFaqs();

    expect(privateCapture.requests.map((request) => request.uri.path), [
      '/api/profile/get',
      '/api/profile/points',
      '/api/profile/medals',
      '/api/profile/cups',
      '/api/notifications/get',
      '/api/faqs/all',
    ]);
    expect(privateCapture.requests[1].queryParameters, {
      'page': 1,
      'perPage': 10,
    });
    expect(privateCapture.requests[2].queryParameters, {
      'page': 2,
      'perPage': 5,
    });
    expect(privateCapture.requests[3].queryParameters, {
      'page': 1,
      'perPage': 10,
    });
    expect(privateCapture.requests[4].queryParameters, {'page': 1});
    expect(
      privateCapture.requests.every(
        (request) => request.headers['Authorization'] == 'Bearer test-token',
      ),
      isTrue,
    );
    expect(publicCapture.requests, isEmpty);
  });

  test('invalid pagination values never reach transport', () async {
    await expectLater(
      source.requestPoints(page: 0),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      source.requestNotifications(page: -1),
      throwsA(isA<AppFailure>()),
    );
    expect(privateCapture.requests, isEmpty);
  });

  test('contact sends exact multipart fields under bearer auth', () async {
    privateCapture.status = 201;
    final result = await LiveAccountRepository(source).submitContact(
      const ContactMessage(
        name: ' سارة ',
        lastName: ' أحمد ',
        phone: ' 0501234567 ',
        description: ' مساعدة ',
      ),
    );
    expect(result.delivered, isTrue);
    final request = privateCapture.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/contact-us/add');
    expect(request.headers['Authorization'], 'Bearer test-token');
    expect(Map.fromEntries((request.data as FormData).fields), {
      'f_name': 'سارة',
      'l_name': 'أحمد',
      'phone': '0501234567',
      'text': 'مساعدة',
    });
    expect(publicCapture.requests, isEmpty);
  });

  test('contact never reports acceptance before a real 2xx response', () async {
    privateCapture.seen = Completer<void>();
    privateCapture.release = Completer<void>();
    final pending = LiveAccountRepository(source).submitContact(
      const ContactMessage(
        name: 'سارة',
        lastName: 'أحمد',
        phone: '0501234567',
        description: 'مساعدة',
      ),
    );
    final expectedFailure = expectLater(pending, throwsA(isA<AppFailure>()));
    var completed = false;
    pending.then<void>((_) {
      completed = true;
    }, onError: (Object _) {});
    await privateCapture.seen!.future;
    expect(completed, isFalse);
    privateCapture.status = 422;
    privateCapture.release!.complete();
    await expectedFailure;
    expect(completed, isFalse);
  });

  test('unverified profile and read mutations remain unavailable', () async {
    final repository = LiveAccountRepository(source);
    await expectLater(
      repository.saveProfile(
        'phone:0501234567',
        const AccountProfile(
          firstName: 'سارة',
          lastName: 'أحمد',
          school: 'مدرسة',
        ),
      ),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      repository.markNotificationRead('phone:0501234567', '1'),
      throwsA(isA<AppFailure>()),
    );
    expect(privateCapture.requests, isEmpty);
  });
}
