import 'package:tamkeen2/features/contact/presentation/contact_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/screens/register_page.dart';
import 'package:tamkeen2/features/auth/presentation/screens/registration_success_page.dart';
import 'package:tamkeen2/features/profile/presentation/school_options_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/registration_options_cubit.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/features/faq/presentation/faq_cubit.dart';
import 'package:tamkeen2/features/gallery/presentation/screens/gallery_page.dart';
import 'package:tamkeen2/features/faq/presentation/screens/faq_page.dart';
import 'package:tamkeen2/features/content/presentation/screens/policy_page.dart';
import 'package:tamkeen2/features/profile/presentation/screens/profile_page.dart';
import 'package:tamkeen2/features/achievements/presentation/screens/achievements_page.dart';
import 'package:tamkeen2/features/notifications/presentation/screens/notifications_page.dart';
import 'package:tamkeen2/features/profile/presentation/screens/edit_profile_page.dart';
import 'package:tamkeen2/features/contact/presentation/screens/contact_page.dart';
import 'package:tamkeen2/features/content/presentation/screens/about_page.dart';
import 'package:tamkeen2/features/auth/presentation/screens/logout_page.dart';
import 'package:tamkeen2/features/courses/presentation/screens/downloads_page.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/screens/splash_page.dart';
import 'package:tamkeen2/features/auth/presentation/screens/login_page.dart';
import 'package:tamkeen2/features/auth/presentation/screens/otp_page.dart';
import 'package:tamkeen2/features/home/presentation/screens/home_page.dart';
import 'package:tamkeen2/features/search/presentation/screens/search_page.dart';
import 'package:tamkeen2/features/courses/presentation/screens/detail_page.dart';
import 'package:tamkeen2/features/courses/presentation/screens/categories_page.dart';
import 'package:tamkeen2/features/history/presentation/screens/assessments_page.dart';
import 'package:tamkeen2/features/courses/presentation/screens/my_learning_page.dart';
import 'package:tamkeen2/features/lessons/presentation/screens/lesson_page.dart';
import 'package:tamkeen2/features/subscriptions/presentation/screens/plans_page.dart';
import 'package:tamkeen2/features/subscriptions/presentation/screens/checkout_page.dart';
import 'package:tamkeen2/features/assessments/presentation/screens/quiz_page.dart';
import 'package:tamkeen2/features/assessments/presentation/screens/quiz_review_page.dart';
import 'package:tamkeen2/features/assessments/presentation/screens/remote_exam_page.dart';
import 'package:tamkeen2/features/lessons/presentation/screens/remote_lesson_page.dart';
import 'package:tamkeen2/features/assessments/domain/assessment.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/core/config/app_config.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/core/router/app_routes.dart';

class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(AuthCubit auth) {
    _subscription = auth.stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter(AuthCubit auth, Listenable refresh) => GoRouter(
  initialLocation: auth.state.user != null
      ? AppRoutes.home
      : auth.state.status == AuthStatus.registrationPending
      ? AppRoutes.register
      : AppRoutes.login,
  refreshListenable: refresh,
  redirect: (context, state) {
    final path = state.uri.path;
    final session = auth.state;
    if (session.status == AuthStatus.restoring) {
      return path == AppRoutes.splash ? null : AppRoutes.splash;
    }
    if (path == AppRoutes.splash &&
        session.user == null &&
        session.status != AuthStatus.registrationPending) {
      return AppRoutes.login;
    }
    final signedIn =
        session.user != null && session.status != AuthStatus.loggingOut;
    const public = {
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.otp,
      AppRoutes.register,
      AppRoutes.terms,
      AppRoutes.privacy,
      AppRoutes.about,
    };
    if (session.status == AuthStatus.registrationPending &&
        {AppRoutes.splash, AppRoutes.login, AppRoutes.otp}.contains(path)) {
      return AppRoutes.register;
    }
    if (!signedIn && !public.contains(path)) {
      return Uri(
        path: AppRoutes.login,
        queryParameters: {'from': state.uri.toString()},
      ).toString();
    }
    if (!signedIn && path == AppRoutes.otp && session.phone == null) {
      return AppRoutes.login;
    }
    if (!signedIn &&
        path == AppRoutes.register &&
        session.status != AuthStatus.registrationPending &&
        !session.registrationFlow) {
      return AppRoutes.login;
    }
    if (signedIn &&
        {
          AppRoutes.splash,
          AppRoutes.login,
          AppRoutes.otp,
          AppRoutes.register,
        }.contains(path)) {
      final target = state.uri.queryParameters['from'];
      if (target != null &&
          target.startsWith('/') &&
          !target.startsWith('//') &&
          !public.contains(Uri.parse(target).path)) {
        return target;
      }
      return AppRoutes.home;
    }
    return null;
  },
  errorBuilder: (context, state) => PageLayout(
    title: AppCopy.pageNotFoundTitle,
    children: [
      const AppText(AppCopy.pageNotFoundMessage),
      TextButton(
        onPressed: () => context.go(
          auth.state.user == null ? AppRoutes.login : AppRoutes.home,
        ),
        child: const AppText(AppCopy.returnAction),
      ),
    ],
  ),
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
    GoRoute(path: AppRoutes.otp, builder: (_, _) => const OtpPage()),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, _) => BlocProvider(
        create: (_) => RegistrationOptionsCubit(auth.repository),
        child: const RegisterPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.registrationSuccess,
      builder: (_, _) => const RegistrationSuccessPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => PopScope(
        canPop: navigationShell.currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && navigationShell.currentIndex != 0) {
            navigationShell.goBranch(0);
          }
        },
        child: AppShell(
          index: navigationShell.currentIndex,
          onIndexChanged: (index) {
            FocusManager.instance.primaryFocus?.unfocus();
            navigationShell.goBranch(index);
          },
          child: navigationShell,
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const ScaffoldMessenger(child: HomePage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myLearning,
              builder: (_, _) =>
                  const ScaffoldMessenger(child: MyLearningPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.gallery,
              builder: (_, _) => const ScaffoldMessenger(child: GalleryPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, _) => const ScaffoldMessenger(child: ProfilePage()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.categories,
      builder: (_, _) => const CategoriesPage(),
    ),
    GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchPage()),
    GoRoute(
      path: '/exam/:id',
      builder: (_, state) => RemoteExamPage(
        examId: state.pathParameters['id']!,
        resultOnly: state.uri.queryParameters['result'] == 'true',
        initial: state.extra is RemoteAssessment
            ? state.extra as RemoteAssessment
            : null,
      ),
    ),
    GoRoute(
      path: '/remote-lesson/:id',
      builder: (_, state) =>
          RemoteLessonPage(lessonId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.assessments,
      builder: (_, _) => const AssessmentsPage(),
    ),
    GoRoute(
      path: AppRoutes.activities,
      builder: (_, _) => const AssessmentsPage(activities: true),
    ),
    GoRoute(
      path: '/gallery/:id',
      builder: (_, state) => AlbumPage(albumId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      pageBuilder: (context, state) => _profileOverlay(
        context,
        state,
        BlocProvider(
          create: (_) => SchoolOptionsCubit(auth.repository),
          child: const EditProfilePage(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.completeProfile,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        opaque: false,
        barrierColor: Theme.of(
          context,
        ).colorScheme.scrim.withValues(alpha: .55),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        child: ScaffoldMessenger(
          child: BlocProvider(
            create: (_) => SchoolOptionsCubit(auth.repository),
            child: const EditProfilePage(completion: true),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/detail/:id',
      builder: (_, state) => DetailPage(courseId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/lesson/:id/:index',
      builder: (_, state) => LessonPage(
        courseId: state.pathParameters['id']!,
        index: int.tryParse(state.pathParameters['index']!) ?? -1,
      ),
    ),
    GoRoute(
      path: '/checkout/:id',
      builder: (_, state) =>
          CheckoutPage(courseId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/quiz/:id',
      builder: (_, state) => QuizPage(
        courseId: state.pathParameters['id']!,
        activity: state.uri.queryParameters['activity'] == 'true',
      ),
    ),
    GoRoute(
      path: AppRoutes.quizReview,
      builder: (_, _) => const QuizReviewPage(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (_, _) => const NotificationsPage(),
    ),
    GoRoute(
      path: AppRoutes.downloads,
      builder: (_, _) => const DownloadsPage(),
    ),
    GoRoute(
      path: AppRoutes.achievements,
      builder: (_, _) => const AchievementsPage(),
    ),
    GoRoute(path: AppRoutes.plans, builder: (_, _) => const PlansPage()),
    GoRoute(
      path: AppRoutes.faq,
      builder: (_, _) => AppConfig.demoMode
          ? const FaqPage()
          : BlocProvider(
              create: (_) => services<FaqCubit>()..load(),
              child: const FaqPage(),
            ),
    ),
    GoRoute(
      path: AppRoutes.privacy,
      builder: (_, _) => const PolicyPage(privacy: true),
    ),
    GoRoute(
      path: AppRoutes.terms,
      builder: (_, _) => const PolicyPage(privacy: false),
    ),
    GoRoute(
      path: AppRoutes.about,
      pageBuilder: (context, state) =>
          _profileOverlay(context, state, const AboutPage()),
    ),
    GoRoute(
      path: AppRoutes.contact,
      pageBuilder: (context, state) => _profileOverlay(
        context,
        state,
        BlocProvider(
          create: (_) => services<ContactCubit>(),
          child: const ContactPage(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.logout,
      pageBuilder: (context, state) =>
          _profileOverlay(context, state, const LogoutPage()),
    ),
  ],
);

// Keep the selected tab visible under the Figma modal and confine transient
// messages to the modal's own scaffold rather than the shell or hidden tabs.
CustomTransitionPage<void> _profileOverlay(
  BuildContext context,
  GoRouterState state,
  Widget child,
) => CustomTransitionPage<void>(
  key: state.pageKey,
  opaque: false,
  barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .55),
  barrierDismissible: true,
  transitionDuration: const Duration(milliseconds: 220),
  reverseTransitionDuration: const Duration(milliseconds: 180),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(opacity: animation, child: child),
  child: ScaffoldMessenger(child: child),
);
