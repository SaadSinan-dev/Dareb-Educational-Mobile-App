import 'package:tamkeen2/features/courses/domain/course_progress.dart';
import 'package:tamkeen2/features/courses/data/stored_course_progress_repository.dart';
import 'package:tamkeen2/features/contact/domain/contact_repository.dart';
import 'package:tamkeen2/features/contact/presentation/contact_cubit.dart';
import 'package:tamkeen2/features/assessments/presentation/preview_quiz_cubit.dart';
import 'package:tamkeen2/features/assessments/domain/preview_quiz_repository.dart';
import 'package:tamkeen2/features/home/presentation/home_cubit.dart';
import 'package:tamkeen2/features/search/presentation/search_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:tamkeen2/features/auth/data/demo_auth_repository.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';
import 'package:tamkeen2/features/auth/data/live_auth_repository.dart';
import 'package:tamkeen2/features/auth/data/postman_auth_data_source.dart';
import 'package:tamkeen2/features/auth/domain/auth_repository.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/account/data/demo_account_repository.dart';
import 'package:tamkeen2/features/account/data/live_account_content_repository.dart';
import 'package:tamkeen2/features/account/data/live_account_repository.dart';
import 'package:tamkeen2/features/account/data/postman_account_data_source.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/account/domain/account_repository.dart';
import 'package:tamkeen2/features/account/presentation/account_cubit.dart';
import 'package:tamkeen2/features/faq/presentation/faq_cubit.dart';
import 'package:tamkeen2/features/courses/data/course_data_source.dart';
import 'package:tamkeen2/features/courses/data/course_repository_impl.dart';
import 'package:tamkeen2/features/home/data/api_home_repository.dart';
import 'package:tamkeen2/features/home/domain/home_repository.dart';
import 'package:tamkeen2/features/search/domain/search_repository.dart';
import 'package:tamkeen2/features/home/domain/get_home_overview.dart';
import 'package:tamkeen2/features/search/domain/search_home.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/domain/subject_repository.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/core/config/app_config.dart';
import 'package:tamkeen2/features/assessments/domain/assessment_repository.dart';
import 'package:tamkeen2/features/lessons/domain/lesson_repository.dart';
import 'package:tamkeen2/features/assessments/data/api_assessment_repository.dart';
import 'package:tamkeen2/features/lessons/data/api_lesson_repository.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'package:tamkeen2/core/storage/key_value_store.dart';
import 'package:tamkeen2/core/storage/preferences_store.dart';

final services = GetIt.instance;

void configureDependencies({
  bool demoMode = AppConfig.demoMode,
  KeyValueStore? store,
  FcmTokenProvider? fcmTokenProvider,
  AuthSessionStore? authSessionStore,
}) {
  if (services.isRegistered<CourseRepository>()) return;
  // An explicit test or debug override must not enable preview data in a release.
  demoMode = demoMode && !const bool.fromEnvironment('dart.vm.product');
  services.registerSingleton<KeyValueStore>(store ?? const PreferencesStore());
  services.registerLazySingleton<AppPreferencesCubit>(
    () => AppPreferencesCubit(services()),
    dispose: (cubit) => cubit.close(),
  );
  services.registerLazySingleton<AuthSessionStore>(
    () => authSessionStore ?? SecureAuthSessionStore(),
  );
  services.registerLazySingleton<ApiClient>(
    () => ApiClient(),
    instanceName: 'public',
  );
  services.registerLazySingleton<ApiClient>(
    () => ApiClient(
      authorizationHeaderProvider: () async {
        if (demoMode) return null;
        final session = await services<AuthSessionStore>().readSession();
        return session == null ? null : 'Bearer ${session.token}';
      },
      onUnauthorized: (authorization) async {
        if (demoMode) return;
        if (authorization == null || !authorization.startsWith('Bearer ')) {
          return;
        }
        final cleared = await services<AuthSessionStore>().clearSession(
          expectedToken: authorization.substring(7),
        );
        if (cleared) services<AuthCubit>().sessionExpired();
      },
    ),
  );
  services.registerLazySingleton<PostmanAuthDataSource>(
    () => PostmanAuthDataSource(
      publicClient: services<ApiClient>(instanceName: 'public'),
      authenticatedClient: services<ApiClient>(),
    ),
  );
  services.registerLazySingleton<AuthRepository>(
    () => demoMode
        ? DemoAuthRepository(services())
        : LiveAuthRepository(
            services(),
            services(),
            fcmTokenProvider: fcmTokenProvider,
          ),
  );
  services.registerLazySingleton<AuthCubit>(
    () => AuthCubit(services()),
    dispose: (cubit) => cubit.close(),
  );
  services.registerLazySingleton<CourseDataSource>(
    () => demoMode
        ? const MockCourseDataSource()
        : ApiCourseDataSource(services<ApiClient>()),
  );
  services.registerLazySingleton<AssessmentRepository>(
    () => ApiAssessmentRepository(services<ApiClient>()),
  );
  services.registerLazySingleton<LessonRepository>(
    () => ApiLessonRepository(services<ApiClient>()),
  );
  services.registerLazySingleton<CourseRepositoryImpl>(
    () => CourseRepositoryImpl(services()),
  );
  services.registerLazySingleton<CourseRepository>(
    () => services<CourseRepositoryImpl>(),
  );
  services.registerLazySingleton<SubjectRepository>(
    () => services<CourseRepositoryImpl>(),
  );
  services.registerLazySingleton<ApiHomeRepository>(
    () => ApiHomeRepository(services<ApiClient>(instanceName: 'public')),
  );
  services.registerLazySingleton<HomeRepository>(
    () => services<ApiHomeRepository>(),
  );
  services.registerLazySingleton<SearchRepository>(
    () => services<ApiHomeRepository>(),
  );
  services.registerLazySingleton<GetHomeOverview>(
    () => GetHomeOverview(services()),
  );
  services.registerLazySingleton<SearchHome>(() => SearchHome(services()));
  services.registerLazySingleton<GetCourses>(() => GetCourses(services()));
  services.registerLazySingleton<PreviewQuizRepository>(
    () => services<CourseRepositoryImpl>(),
  );
  services.registerFactory<PreviewQuizCubit>(
    () => PreviewQuizCubit(services()),
  );
  services.registerFactory<HomeCubit>(() => HomeCubit(services()));
  services.registerFactory<SearchCubit>(() => SearchCubit(services()));
  services.registerLazySingleton<CourseProgressRepository>(
    () => StoredCourseProgressRepository(services()),
  );
  services.registerFactory<CourseCubit>(
    () => CourseCubit(
      services(),
      services(),
      progress: services(),
      demoMode: demoMode,
    ),
  );
  services.registerLazySingleton<PostmanAccountDataSource>(
    () => PostmanAccountDataSource(
      publicClient: services<ApiClient>(instanceName: 'public'),
      authenticatedClient: services<ApiClient>(),
    ),
  );
  services.registerLazySingleton<AccountContentRepository>(
    () => LiveAccountContentRepository(services()),
  );
  services.registerLazySingleton<AccountRepository>(
    () => demoMode
        ? DemoAccountRepository(services())
        : LiveAccountRepository(services()),
  );
  services.registerLazySingleton<ContactRepository>(
    () => services<AccountRepository>(),
  );
  services.registerFactory<ContactCubit>(() => ContactCubit(services()));
  services.registerFactory<AccountCubit>(() => AccountCubit(services()));
  services.registerFactory<FaqCubit>(() => FaqCubit(services()));
}
