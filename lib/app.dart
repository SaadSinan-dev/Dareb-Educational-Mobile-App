import 'package:tamkeen2/features/assessments/presentation/preview_quiz_cubit.dart';
import 'package:tamkeen2/core/config/app_runtime.dart';
import 'package:tamkeen2/features/home/presentation/home_cubit.dart';
import 'package:tamkeen2/features/search/presentation/search_cubit.dart';
import 'package:tamkeen2/features/assessments/domain/assessment_repository.dart';
import 'package:tamkeen2/features/lessons/domain/lesson_repository.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/application/app_bootstrap_cubit.dart';
import 'package:tamkeen2/application/app_session_coordinator.dart';
import 'package:tamkeen2/features/auth/presentation/screens/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/config/app_config.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/router/app_router.dart';
import 'package:tamkeen2/core/theme/app_theme.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/account/presentation/account_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

class LearningApp extends StatefulWidget {
  const LearningApp({super.key});
  @override
  State<LearningApp> createState() => _LearningAppState();
}

class _LearningAppState extends State<LearningApp> {
  late final PreviewQuizCubit _quiz;
  late final HomeCubit _home;
  late final SearchCubit _search;
  late final AuthCubit _auth;
  late final AppPreferencesCubit _preferences;
  late final CourseCubit _learning;
  late final AccountCubit _account;
  late final AuthRouterRefresh _refresh;
  GoRouter? _router;
  late final AppBootstrapCubit _bootstrap;
  late final AppSessionCoordinator _sessions;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _quiz = services<PreviewQuizCubit>();
    _home = services<HomeCubit>();
    _search = services<SearchCubit>();
    _auth = services<AuthCubit>();
    _preferences = services<AppPreferencesCubit>();
    _learning = services<CourseCubit>();
    _account = services<AccountCubit>();
    _refresh = AuthRouterRefresh(_auth);
    _sessions = AppSessionCoordinator(
      _auth,
      _learning,
      _account,
      _home,
      _search,
      _quiz,
    );
    _bootstrap = AppBootstrapCubit(_auth, _preferences)..initialize();
    _lifecycle = AppLifecycleListener(onResume: _auth.refreshSession);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _sessions.dispose();
    _bootstrap.close();
    _router?.dispose();
    _refresh.dispose();
    _quiz.close();
    _home.close();
    _search.close();
    _learning.close();
    _account.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AssessmentRepository>.value(
        value: services<AssessmentRepository>(),
      ),
      RepositoryProvider<LessonRepository>.value(
        value: services<LessonRepository>(),
      ),
      RepositoryProvider<AccountContentRepository>.value(
        value: services<AccountContentRepository>(),
      ),
    ],
    child: AppRuntime(
      preview: _learning.demoMode,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _quiz),
          BlocProvider.value(value: _home),
          BlocProvider.value(value: _search),
          BlocProvider.value(value: _auth),
          BlocProvider.value(value: _learning),
          BlocProvider.value(value: _account),
          BlocProvider.value(value: _preferences),
          BlocProvider.value(value: _bootstrap),
        ],
        child: BlocBuilder<AppPreferencesCubit, AppPreferencesState>(
          builder: (context, preferences) =>
              BlocBuilder<AppBootstrapCubit, BootstrapState>(
                builder: (context, startup) {
                  if (startup.resolved) {
                    _router ??= createAppRouter(_auth, _refresh);
                  }
                  final configuredRouter = _router;
                  if (configuredRouter == null) {
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.lightFor(preferences.languageCode),
                      darkTheme: AppTheme.darkFor(preferences.languageCode),
                      themeMode: preferences.themeMode,
                      locale: Locale(preferences.languageCode),
                      supportedLocales: AppLocalizations.supportedLocales,
                      localizationsDelegates: [
                        ...GlobalMaterialLocalizations.delegates,
                        AppLocalizations.delegate,
                      ],
                      home: startup.status == BootstrapStatus.sessionError
                          ? Scaffold(
                              body: SafeArea(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppText(
                                        startup.error ??
                                            AppCopy.unexpectedClientError,
                                      ),
                                      TextButton(
                                        onPressed: _bootstrap.initialize,
                                        child: const AppText(
                                          AppCopy.retryAction,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const SplashPage(),
                    );
                  }
                  return MaterialApp.router(
                    onGenerateTitle: (context) => context.tr(AppCopy.appName),
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightFor(preferences.languageCode),
                    darkTheme: AppTheme.darkFor(preferences.languageCode),
                    themeMode: preferences.themeMode,
                    locale: Locale(preferences.languageCode),
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates: [
                      ...GlobalMaterialLocalizations.delegates,
                      AppLocalizations.delegate,
                    ],
                    builder: (appContext, child) => Directionality(
                      textDirection: preferences.languageCode == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: AppConfig.demoMode
                          ? Stack(
                              children: [
                                child ?? const SizedBox.shrink(),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: appContext.colors.secondary,
                                        borderRadius: const BorderRadius.only(
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        child: AppText(
                                          AppCopy.previewBadge,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: appContext.colors.onBrand,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : child ?? const SizedBox.shrink(),
                    ),

                    routerConfig: configuredRouter,
                  );
                },
              ),
        ),
      ),
    ),
  );
}
