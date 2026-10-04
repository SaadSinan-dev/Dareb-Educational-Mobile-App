import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/category_grid.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_artwork.dart';
import 'package:tamkeen2/features/home/presentation/home_cubit.dart';
import 'package:tamkeen2/features/home/presentation/widgets/home_media_image.dart';
import 'package:tamkeen2/features/home/presentation/widgets/home_design_slider.dart';
import 'package:tamkeen2/features/home/presentation/widgets/home_materials_strip.dart';
import 'package:tamkeen2/features/home/presentation/widgets/home_welcome_summary.dart';
import 'package:tamkeen2/features/search/presentation/search_cubit.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

class _HomeOverviewSkeleton extends StatelessWidget {
  const _HomeOverviewSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr(AppCopy.loadingCoursesLabel),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SurfaceCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 130, height: 19),
                    SizedBox(height: 12),
                    SkeletonBlock(width: 85, height: 13),
                  ],
                ),
              ),
              SkeletonBlock(width: 82, height: 82, radius: 41),
            ],
          ),
        ),
        const SkeletonBlock(height: 170, radius: 12),
        const SizedBox(height: 18),
        const SkeletonBlock(width: 100, height: 18),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: SkeletonBlock(height: 70, radius: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const SkeletonBlock(width: 100, height: 18),
        const SizedBox(height: 10),
        const SkeletonBlock(height: 130, radius: 12),
      ],
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int banner = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.read<CourseCubit>().demoMode) {
        context.read<HomeCubit>().load();
      }
    });
  }

  Widget _publicHome(BuildContext context, CourseCubit cubit) {
    final state = cubit.state;
    final homeState = context.watch<HomeCubit>().state;
    final home = homeState.data;
    final byId = {for (final course in state.courses) course.id: course};
    final featured = (home?.featuredCourseIds ?? const <String>[])
        .map((id) => byId[id])
        .whereType<Course>()
        .toList(growable: false);
    final progress = home == null
        ? 0.0
        : (home.completionRate / 100).clamp(0.0, 1.0).toDouble();
    return CatalogContent(
      state: state,
      title: AppCopy.welcomeBack,
      onRefresh: () async {
        await Future.wait([
          cubit.load(),
          context.read<HomeCubit>().load(force: true),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          22,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppSearch(
            onChanged: context.read<SearchCubit>().search,
            onTap: () => context.push(AppRoutes.search),
          ),
          learningSectionGap,
          if (homeState.status == ResourceStatus.loading)
            const _HomeOverviewSkeleton(),
          if (homeState.status == ResourceStatus.failure)
            SurfaceCard(
              child: Column(
                children: [
                  AppText(
                    homeState.error ?? AppCopy.serviceCurrentlyUnavailable,
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<HomeCubit>().load(force: true),
                    child: const AppText(AppCopy.retryAction),
                  ),
                ],
              ),
            ),
          if (home != null) ...[
            SurfaceCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          AppCopy.curriculumProgress,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        AppText(
                          '${AppCopy.subjectsLabel}: ${home.subjectCount}',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 82,
                    height: 82,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: context.colors.border,
                          ),
                        ),
                        AppText('${home.completionRate}%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            learningSectionGap,
            HomeDesignSlider(onAccountTap: _completeProfile),
            SectionTitle(
              AppCopy.subjectsLabel,
              onSeeAll: () => context.push(AppRoutes.categories),
            ),
            CategoryGrid(
              horizontal: true,
              categories: home.subjects.map((item) => item.name).toList(),
              onSelect: (category) {
                cubit.selectCategory(category);
                context.push(AppRoutes.categories);
              },
            ),
            if (home.news.isNotEmpty) ...[
              const SectionTitle(AppCopy.latestNews),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: home.news.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final media = home.news[index];
                    return InkWell(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (dialog) => AlertDialog(
                          title: const AppText(AppCopy.latestNews),
                          content: homeMediaImage(
                            dialog,
                            media,
                            width: 300,
                            height: 200,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialog),
                              child: const AppText(AppCopy.closeAction),
                            ),
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: homeMediaImage(
                          context,
                          media,
                          width: 240,
                          height: 130,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
          SectionTitle(
            home == null ? AppCopy.coursesTitle : AppCopy.featuredCourses,
            onSeeAll: () => context.push(AppRoutes.categories),
          ),
          HomeMaterialsStrip(courses: home == null ? state.courses : featured),
        ],
      ),
    );
  }

  Future<void> _completeProfile() async {
    final proceed = await showDialog<bool>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .67),
      builder: (_) => const AppDecisionDialog(
        title: AppCopy.completeAccountNow,
        confirmLabel: AppCopy.completeAccountAction,
      ),
    );
    if (proceed == true && mounted) context.push(AppRoutes.completeProfile);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CourseCubit>();
    if (!cubit.demoMode) return _publicHome(context, cubit);
    final state = cubit.state;
    final total = state.courses.fold<int>(
      0,
      (sum, c) => sum + c.lessons.length,
    );
    final progress = total == 0
        ? 0.0
        : (state.completedLessonIds.length / total).clamp(0.0, 1.0);
    return CatalogContent(
      state: state,
      title: AppCopy.welcomeBack,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          22,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          HomeWelcomeSummary(
            displayName:
                context.watch<AuthCubit>().state.user?.displayName ?? '',
            courseCount: state.courses.length,
            completedLessons: state.completedLessonIds.length,
            onAchievements: () => context.push(AppRoutes.achievements),
          ),
          learningSectionGap,
          AppSearch(
            onChanged: context.read<CourseCubit>().search,
            onTap: () => context.push(AppRoutes.search),
          ),
          learningSectionGap,
          SurfaceCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        AppCopy.curriculumProgress,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      AppText(AppCopy.courseProgressEncouragement),
                      AppText(
                        AppCopy.format(AppCopy.courseCount, [
                          state.courses.length,
                        ]),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.myLearning),
                        child: AppText(AppCopy.viewDetailsLabel),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 82,
                  height: 82,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: context.colors.border,
                        ),
                      ),
                      AppText(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          color: context.colors.secondary,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          learningSectionGap,
          LayoutBuilder(
            builder: (context, constraints) {
              final textStyle = TextStyle(
                color: context.colors.onBrand,
                fontSize: 16,
                height: 1.5,
              );
              final painter = TextPainter(
                text: TextSpan(
                  text: context.tr(AppCopy.excellenceStartsHere),
                  style: textStyle,
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: (constraints.maxWidth - 30) * .6);
              final height = (painter.height + 80).clamp(144.0, 420.0);
              painter.dispose();
              return SizedBox(
                height: height,
                child: PageView(
                  onPageChanged: (value) => setState(() => banner = value),
                  children: [
                    for (final art in ['graduates', 'student', 'teacher'])
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppText(
                                    AppCopy.excellenceStartsHere,
                                    textAlign: TextAlign.center,
                                    style: textStyle,
                                  ),
                                  TextButton(
                                    onPressed: _completeProfile,
                                    style: TextButton.styleFrom(
                                      foregroundColor: context.colors.onBrand,
                                    ),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: AppText(AppCopy.checkAccountNow),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: courseAsset('illustrations/$art'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: banner == i ? 25 : 8,
                  height: 8,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: banner == i
                        ? context.colors.secondary
                        : context.colors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
          SectionTitle(
            AppCopy.subjectsLabel,
            onSeeAll: () {
              context.read<CourseCubit>().selectCategory(null);
              context.push(AppRoutes.categories);
            },
          ),
          CategoryGrid(
            horizontal: true,
            categories: state.courses.map((c) => c.category).toSet().toList(),
            onSelect: (category) {
              context.read<CourseCubit>().selectCategory(category);
              context.push(AppRoutes.categories);
            },
          ),
          const SectionTitle(AppCopy.latestNews),
          InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (dialog) => AlertDialog(
                title: AppText(AppCopy.learningJourney),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    courseAsset('images/news', height: 140),
                    AppText(AppCopy.learningJourneyDescription),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: AppText(AppCopy.closeAction),
                  ),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: courseAsset(
                'images/news',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SectionTitle(
            AppCopy.featuredCourses,
            onSeeAll: () => context.push(AppRoutes.categories),
          ),
          HomeMaterialsStrip(courses: state.courses),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.assessments),
            icon: Icon(Icons.quiz_outlined),
            label: AppText(AppCopy.myQuizzesAndDailyActivities),
          ),
        ],
      ),
    );
  }
}
