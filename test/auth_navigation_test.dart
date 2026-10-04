import 'package:tamkeen2/features/auth/presentation/registration_options_cubit.dart';
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/storage/key_value_store.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';
import 'package:tamkeen2/features/auth/data/demo_auth_repository.dart';
import 'package:tamkeen2/features/auth/data/live_auth_repository.dart';
import 'package:tamkeen2/features/auth/data/postman_auth_data_source.dart';
import 'package:tamkeen2/features/auth/domain/auth_user.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/auth_pages.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';

class _MemoryStore implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}

class _LogoBundle extends CachingAssetBundle {
  static final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZQxAAAAAASUVORK5CYII=',
  );

  @override
  Future<ByteData> load(String key) async {
    if (key == 'assets/images/logo_white.png') {
      return ByteData.sublistView(_png);
    }
    return rootBundle.load(key);
  }
}

class _DelayedResendRepository extends DemoAuthRepository {
  _DelayedResendRepository(super.store);
  final allowResend = Completer<void>();
  int requests = 0;

  @override
  Future<void> requestCode(String phone) async {
    requests++;
    if (requests > 1) await allowResend.future;
    await super.requestCode(phone);
  }
}

class _PendingRegistrationRepository extends DemoAuthRepository {
  _PendingRegistrationRepository(super.store);
  bool loggedOut = false;

  @override
  Future<AuthUser?> restoreSession() async => const AuthUser(
    id: 'pending-user',
    phone: '0912345678',
    profileComplete: false,
  );

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

class _SchoolLookupRepository extends DemoAuthRepository {
  _SchoolLookupRepository(
    super.store, {
    this.emptyFirst = false,
    this.errorFirst = false,
  });

  final bool emptyFirst;
  final bool errorFirst;
  int governorateCalls = 0;
  final schoolQueries = <(int, String)>[];

  @override
  Future<List<GovernorateOption>> governorates() async {
    governorateCalls++;
    return const [
      GovernorateOption(key: 'damascus', name: 'دمشق'),
      GovernorateOption(key: 'aleppo', name: 'حلب'),
    ];
  }

  @override
  Future<List<RegistrationOption>> schools({
    required int type,
    required String governorate,
  }) async {
    schoolQueries.add((type, governorate));
    if (governorate == 'damascus' && errorFirst && schoolQueries.length == 1) {
      throw const AppFailure('School lookup failed');
    }
    if (governorate == 'damascus' && emptyFirst) return const [];
    return const [RegistrationOption(id: 27, name: 'مدرسة من الخادم')];
  }
}

class _CaptureSchoolRegistrationRepository extends _SchoolLookupRepository {
  _CaptureSchoolRegistrationRepository(super.store);

  RegistrationDraft? submitted;

  @override
  Future<AuthUser> register(RegistrationDraft draft) {
    submitted = draft;
    return super.register(draft);
  }
}

class _DelayedSchoolRepository extends _SchoolLookupRepository {
  _DelayedSchoolRepository(super.store);

  final releaseAleppo = Completer<void>();

  @override
  Future<List<RegistrationOption>> schools({
    required int type,
    required String governorate,
  }) async {
    if (governorate == 'aleppo') await releaseAleppo.future;
    return super.schools(type: type, governorate: governorate);
  }
}

class _NoNetworkAdapter implements HttpClientAdapter {
  int attempts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    attempts++;
    throw StateError('Registration has no verified transport contract');
  }

  @override
  void close({bool force = false}) {}
}

class _EmptySessions implements AuthSessionStore {
  @override
  Future<AuthSession?> readSession() async => null;
  @override
  Future<void> saveSession(AuthSession value) async {}
  @override
  Future<bool> clearSession({String? expectedToken}) async =>
      expectedToken == null;
  @override
  Future<String> deviceId() async => 'test-device';
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _reachRegistrationDetails(WidgetTester tester) async {
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'التالي'));
  await _tapVisible(tester, find.text('أنثى'));
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'التالي'));
  await _tapVisible(tester, find.text('صديق'));
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'التالي'));
  await _tapVisible(tester, find.text('مدرسة'));
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'التالي'));
  await _tapVisible(tester, find.text('بكالوريا علمي'));
  await _tapVisible(tester, find.byType(DropdownButtonFormField<int>).first);
  await _tapVisible(tester, find.text('الفرع التجريبي').last);
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'التأكيد'));
}

void main() {
  testWidgets('school lookup stays loading until the new list arrives', (
    tester,
  ) async {
    final repository = _DelayedSchoolRepository(_MemoryStore());
    final auth = AuthCubit(repository);
    await auth.requestCode('0501234567', forRegistration: true);
    await auth.verifyCode('1234');
    addTearDown(auth.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: auth,
        child: DefaultAssetBundle(
          bundle: _LogoBundle(),
          child: MaterialApp(home: _registrationPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _reachRegistrationDetails(tester);
    await _tapVisible(tester, find.byType(DropdownButtonFormField<String>));
    await _tapVisible(tester, find.text('حلب').last);
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester
          .state<FormFieldState<int>>(find.byType(DropdownButtonFormField<int>))
          .value,
      isNull,
    );

    repository.releaseAleppo.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await _tapVisible(tester, find.byType(DropdownButtonFormField<int>));
    await _tapVisible(tester, find.text('مدرسة من الخادم').last);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'school choice resets when institution type or governorate changes',
    (tester) async {
      final repository = _SchoolLookupRepository(_MemoryStore());
      final auth = AuthCubit(repository);
      await auth.requestCode('0501234567', forRegistration: true);
      await auth.verifyCode('1234');
      addTearDown(auth.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: DefaultAssetBundle(
            bundle: _LogoBundle(),
            child: MaterialApp(home: _registrationPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _reachRegistrationDetails(tester);
      var schoolField = find.byType(DropdownButtonFormField<int>);
      await _tapVisible(tester, schoolField);
      await _tapVisible(tester, find.text('مدرسة من الخادم').last);
      expect(tester.state<FormFieldState<int>>(schoolField).value, 27);

      await _tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, AppCopy.goBackAction),
      );
      await _tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, AppCopy.goBackAction),
      );
      await _tapVisible(tester, find.text('معهد'));
      await tester.pumpAndSettle();
      expect(repository.schoolQueries.last, (2, 'damascus'));
      await _tapVisible(
        tester,
        find.widgetWithText(FilledButton, AppCopy.nextAction),
      );
      await _tapVisible(
        tester,
        find.widgetWithText(FilledButton, AppCopy.confirmAction),
      );
      schoolField = find.byType(DropdownButtonFormField<int>);
      expect(tester.state<FormFieldState<int>>(schoolField).value, isNull);

      await _tapVisible(tester, find.byType(DropdownButtonFormField<String>));
      await _tapVisible(tester, find.text('حلب').last);
      await tester.pumpAndSettle();
      expect(repository.schoolQueries.last, (2, 'aleppo'));
      expect(tester.state<FormFieldState<int>>(schoolField).value, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selected backend school is submitted as school_id', (
    tester,
  ) async {
    final repository = _CaptureSchoolRegistrationRepository(_MemoryStore());
    final auth = AuthCubit(repository);
    await auth.requestCode('0501234567', forRegistration: true);
    await auth.verifyCode('1234');
    final router = GoRouter(
      initialLocation: AppRoutes.register,
      routes: [
        GoRoute(
          path: AppRoutes.register,
          builder: (_, _) => _registrationPage(),
        ),
        GoRoute(
          path: AppRoutes.registrationSuccess,
          builder: (_, _) => const Scaffold(body: Text('Registered')),
        ),
      ],
    );
    addTearDown(auth.close);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider.value(
        value: auth,
        child: DefaultAssetBundle(
          bundle: _LogoBundle(),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _reachRegistrationDetails(tester);
    await tester.enterText(find.byType(TextField).at(0), 'سارة');
    await tester.enterText(find.byType(TextField).at(1), 'أحمد');
    await tester.enterText(find.byType(TextField).at(2), 'sara@example.com');
    await _tapVisible(tester, find.byType(DropdownButtonFormField<int>));
    await _tapVisible(tester, find.text('مدرسة من الخادم').last);
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'التالي'));
    await _tapVisible(tester, find.byType(Checkbox));
    await _tapVisible(
      tester,
      find.widgetWithText(FilledButton, AppCopy.createAccountAction),
    );
    await tester.pumpAndSettle();

    expect(repository.submitted?.schoolId, 27);
    expect(repository.submitted?.school, 'مدرسة من الخادم');
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.registrationSuccess,
    );
    expect(tester.takeException(), isNull);
  });

  for (final mode in ['empty', 'error']) {
    testWidgets('school lookup $mode state recovers without fake choices', (
      tester,
    ) async {
      final repository = _SchoolLookupRepository(
        _MemoryStore(),
        emptyFirst: mode == 'empty',
        errorFirst: mode == 'error',
      );
      final auth = AuthCubit(repository);
      await auth.requestCode('0501234567', forRegistration: true);
      await auth.verifyCode('1234');
      addTearDown(auth.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: DefaultAssetBundle(
            bundle: _LogoBundle(),
            child: MaterialApp(home: _registrationPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _reachRegistrationDetails(tester);
      await tester.pumpAndSettle();

      final schoolField = find.byType(DropdownButtonFormField<int>);
      expect(tester.state<FormFieldState<int>>(schoolField).value, isNull);
      expect(find.text('مدرسة من الخادم'), findsNothing);
      expect(
        find.text(
          mode == 'empty'
              ? AppCopy.noSchoolsForSelection
              : 'School lookup failed',
        ),
        findsOneWidget,
      );
      if (mode == 'empty') {
        await _tapVisible(tester, find.byType(DropdownButtonFormField<String>));
        await _tapVisible(tester, find.text('حلب').last);
      } else {
        await _tapVisible(
          tester,
          find.widgetWithText(TextButton, AppCopy.retryAction).last,
        );
      }
      await tester.pumpAndSettle();
      expect(repository.governorateCalls, 1);
      expect(
        repository.schoolQueries,
        mode == 'empty'
            ? [(1, 'damascus'), (1, 'aleppo')]
            : [(1, 'damascus'), (1, 'damascus')],
      );
      await _tapVisible(tester, schoolField);
      await _tapVisible(tester, find.text('مدرسة من الخادم').last);
      expect(tester.state<FormFieldState<int>>(schoolField).value, 27);
      expect(find.text('مدرسة من الخادم'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restored incomplete registration can exit to login', (
    tester,
  ) async {
    final repository = _PendingRegistrationRepository(_MemoryStore());
    final auth = AuthCubit(repository);
    await auth.restore();
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(path: '/register', builder: (_, _) => _registrationPage()),
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      ],
    );
    addTearDown(auth.close);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/register');
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();
    expect(repository.loggedOut, isTrue);
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(430, 900), const Size(1280, 800)]) {
    testWidgets(
      'registration phone request reaches the real API at ${size.width.toInt()}px',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final publicClient = ApiClient(baseUrl: 'https://example.test/api');
        final privateClient = ApiClient(baseUrl: 'https://example.test/api');
        final adapter = _NoNetworkAdapter();
        publicClient.dio.httpClientAdapter = adapter;
        privateClient.dio.httpClientAdapter = adapter;
        final cubit = AuthCubit(
          LiveAuthRepository(
            PostmanAuthDataSource(
              publicClient: publicClient,
              authenticatedClient: privateClient,
            ),
            _EmptySessions(),
          ),
        );
        addTearDown(cubit.close);
        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: DefaultAssetBundle(
              bundle: _LogoBundle(),
              child: const MaterialApp(home: LoginPage()),
            ),
          ),
        );
        await tester.enterText(find.byType(TextField).first, '15555215554');
        await tester.tap(find.text('إنشاء حساب جديد'));
        await tester.pumpAndSettle();
        expect(adapter.attempts, 1);
        expect(cubit.state.status, AuthStatus.failure);
        expect(cubit.state.user, isNull);
        expect(
          find.text('التسجيل غير متاح حالياً. يرجى التواصل مع الدعم.'),
          findsNothing,
        );
      },
    );
  }
  testWidgets('OTP digits read left to right in an Arabic screen', (
    tester,
  ) async {
    final key = GlobalKey<OtpDigitsState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(child: OtpDigits(key: key)),
          ),
        ),
      ),
    );
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));
    for (var index = 0; index < 3; index++) {
      expect(
        tester.getCenter(fields.at(index)).dx,
        lessThan(tester.getCenter(fields.at(index + 1)).dx),
      );
    }
    for (var index = 0; index < 4; index++) {
      await tester.enterText(fields.at(index), '${index + 1}');
    }
    expect(key.currentState!.code, '1234');
  });

  testWidgets('resending from OTP keeps a single OTP route', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = AuthCubit(DemoAuthRepository(_MemoryStore()));
    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
        GoRoute(path: AppRoutes.otp, builder: (_, _) => const OtpPage()),
      ],
    );
    addTearDown(() async {
      router.dispose();
      await cubit.close();
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: DefaultAssetBundle(
          bundle: _LogoBundle(),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '0501234567');
    await tester.tap(find.text('سجل دخول'));
    await tester.pumpAndSettle();
    expect(cubit.state.status, AuthStatus.codeSent);
    expect(tester.takeException(), isNull);
    expect(router.routerDelegate.currentConfiguration.matches, hasLength(2));
    expect(find.byType(OtpPage), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
    await tester.pump();
    final resend = find.widgetWithText(TextButton, 'أعد إرسال الكود');
    expect(tester.widget<TextButton>(resend).onPressed, isNotNull);
    await tester.tap(resend);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.matches, hasLength(2));
    expect(find.byType(OtpPage, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late resend does not reopen OTP after editing the phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _DelayedResendRepository(_MemoryStore());
    final cubit = AuthCubit(repository);
    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
        GoRoute(path: AppRoutes.otp, builder: (_, _) => const OtpPage()),
      ],
    );
    addTearDown(() async {
      router.dispose();
      await cubit.close();
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: DefaultAssetBundle(
          bundle: _LogoBundle(),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '0501234567');
    await tester.tap(find.text('سجل دخول'));
    await tester.pumpAndSettle();
    expect(find.byType(OtpPage), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
    await tester.tap(find.widgetWithText(TextButton, 'أعد إرسال الكود'));
    await tester.pump();
    await tester.tap(find.text('تعديل الرقم'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    repository.allowResend.complete();
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.matches, hasLength(1));
    expect(find.byType(OtpPage, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in <double>[320, 360, 390, 430, 600, 768]) {
    testWidgets(
      'full OTP page stays usable at ${width.toInt()}px with keyboard',
      (tester) async {
        final height = width <= 430 ? 640.0 : 900.0;
        await tester.binding.setSurfaceSize(Size(width, height));
        addTearDown(() async {
          tester.view.resetViewInsets();
          await tester.binding.setSurfaceSize(null);
        });
        final cubit = AuthCubit(DemoAuthRepository(_MemoryStore()));
        await cubit.requestCode('0501234567');
        addTearDown(cubit.close);
        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: DefaultAssetBundle(
              bundle: _LogoBundle(),
              child: const MaterialApp(home: OtpPage()),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(OtpPage), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(4));
        await tester.showKeyboard(find.byType(TextField).first);
        tester.view.viewInsets = FakeViewPadding(
          bottom: 300 * tester.view.devicePixelRatio,
        );
        await tester.pump();
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'التأكيد'),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.widgetWithText(FilledButton, 'التأكيد')).bottom,
          lessThanOrEqualTo(height - 300),
        );
      },
    );

    testWidgets(
      'registration choices, details and terms fit ${width.toInt()}px',
      (tester) async {
        final height = width <= 430 ? 640.0 : 900.0;
        await tester.binding.setSurfaceSize(Size(width, height));
        addTearDown(() async {
          tester.view.resetViewInsets();
          await tester.binding.setSurfaceSize(null);
        });
        final cubit = AuthCubit(DemoAuthRepository(_MemoryStore()));
        await cubit.requestCode('0501234567', forRegistration: true);
        await cubit.verifyCode('1234');
        addTearDown(cubit.close);
        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: DefaultAssetBundle(
              bundle: _LogoBundle(),
              child: MaterialApp(home: _registrationPage()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _tapVisible(tester, find.widgetWithText(FilledButton, 'التالي'));
        await _tapVisible(tester, find.text('أنثى'));
        await _tapVisible(tester, find.widgetWithText(FilledButton, 'التالي'));
        await _tapVisible(tester, find.text('صديق'));
        await _tapVisible(tester, find.widgetWithText(FilledButton, 'التالي'));
        await _tapVisible(tester, find.text('مدرسة'));
        await _tapVisible(tester, find.widgetWithText(FilledButton, 'التالي'));
        await _tapVisible(tester, find.text('بكالوريا علمي'));
        await _tapVisible(
          tester,
          find.byType(DropdownButtonFormField<int>).first,
        );
        await _tapVisible(tester, find.text('الفرع التجريبي').last);
        await _tapVisible(tester, find.widgetWithText(FilledButton, 'التأكيد'));
        expect(find.byType(TextField), findsNWidgets(4));
        tester.view.viewInsets = FakeViewPadding(
          bottom: 300 * tester.view.devicePixelRatio,
        );
        await tester.pump();
        await tester.ensureVisible(find.byType(TextField).last);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byType(TextField).last).bottom,
          lessThanOrEqualTo(height - 300),
        );
        tester.view.resetViewInsets();
        await tester.pump();
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'سارة');
        await tester.enterText(fields.at(1), 'أحمد');
        await tester.enterText(fields.at(2), 'sara@example.com');
        await tester.pumpAndSettle();
        expect(
          tester
              .state<FormFieldState<String>>(
                find.byType(DropdownButtonFormField<String>),
              )
              .value,
          'preview',
        );
        await _tapVisible(tester, find.byType(DropdownButtonFormField<int>));
        await _tapVisible(tester, find.text('المدرسة التجريبية').last);
        expect(
          tester
              .state<FormFieldState<int>>(
                find.byType(DropdownButtonFormField<int>),
              )
              .value,
          1,
        );
        await _tapVisible(tester, find.widgetWithText(FilledButton, 'التالي'));
        expect(find.text('الشروط والأحكام'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _registrationPage() => Builder(
  builder: (context) => BlocProvider(
    create: (_) =>
        RegistrationOptionsCubit(context.read<AuthCubit>().repository),
    child: const RegisterPage(),
  ),
);
