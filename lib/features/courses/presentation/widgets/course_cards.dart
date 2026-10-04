import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.compact = false});
  final Course course;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFFCCDAFF)
              : context.colors.border,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.detail(course.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: compact ? 68 : 86,
                height: compact ? 78 : 96,
                decoration: BoxDecoration(
                  color: context.colors.softBlue,
                  shape: BoxShape.circle,
                ),
                child: _artwork(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      course.title,
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      course.teacher,
                      style: TextStyle(color: context.colors.muted),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      AppCopy.format(AppCopy.lessonCountLabel, [
                        course.lessons.length,
                      ]),
                      style: TextStyle(color: context.colors.primary),
                    ),
                  ],
                ),
              ),
              if (!compact)
                IconButton(
                  tooltip: context.tr(AppCopy.saveCourseAction),
                  onPressed: () =>
                      context.read<CourseCubit>().toggleSaved(course.id),
                  icon: Icon(
                    context.watch<CourseCubit>().state.savedIds.contains(
                          course.id,
                        )
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: context.colors.secondary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _artwork(BuildContext context) {
    final url = course.imageUrl?.trim();
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty) {
      return ClipOval(
        child: Image.network(
          uri.toString(),
          fit: BoxFit.cover,
          width: compact ? 68 : 86,
          height: compact ? 78 : 96,
          semanticLabel: course.title,
          errorBuilder: (_, _, _) => _placeholder(context),
        ),
      );
    }
    if (url != null) return _placeholder(context);
    return Image.asset(
      course.id == 'science'
          ? 'assets/illustrations/teacher_photo.png'
          : 'assets/illustrations/teacher.png',
      fit: BoxFit.contain,
      semanticLabel: course.title,
    );
  }

  Widget _placeholder(BuildContext context) => Center(
    child: Icon(
      Icons.menu_book_outlined,
      color: context.colors.secondary,
      size: compact ? 28 : 36,
      semanticLabel: course.title,
    ),
  );
}

class CourseList extends StatelessWidget {
  const CourseList({super.key, required this.courses});
  final List<Course> courses;
  @override
  Widget build(BuildContext context) => courses.isEmpty
      ? const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: AppText(AppCopy.noCoursesTitle)),
        )
      : Column(
          children: [for (final course in courses) CourseCard(course: course)],
        );
}

class LoadingContent extends StatelessWidget {
  const LoadingContent({
    super.key,
    required this.state,
    required this.child,
    this.embedded = false,
  });
  final bool embedded;
  final CourseState state;
  final Widget child;
  @override
  Widget build(BuildContext context) => switch (state.status) {
    LoadStatus.initial ||
    LoadStatus.loading => _CourseCatalogSkeleton(embedded: embedded),
    LoadStatus.failure => _failure(context),
    LoadStatus.ready || LoadStatus.refreshing || LoadStatus.empty => child,
  };

  Widget _failure(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            state.error ?? AppCopy.loadingFailedTitle,
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: context.read<CourseCubit>().load,
            child: const AppText(AppCopy.retryAction),
          ),
        ],
      ),
    );
    if (!embedded) return Center(child: content);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: content),
        ),
      ),
    );
  }
}

class _CourseCatalogSkeleton extends StatelessWidget {
  const _CourseCatalogSkeleton({this.embedded = false});
  final bool embedded;
  @override
  Widget build(BuildContext context) {
    final children = [
      const SkeletonBlock(height: 48, radius: 10),
      const SizedBox(height: 24),
      const SkeletonBlock(width: 140, height: 20),
      const SizedBox(height: 16),
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SurfaceCard(
            child: Row(
              children: [
                const SkeletonBlock(width: 86, height: 96, radius: 44),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(height: 17),
                      SizedBox(height: 11),
                      SkeletonBlock(width: 110, height: 14),
                      SizedBox(height: 10),
                      SkeletonBlock(width: 74, height: 14),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const SkeletonBlock(width: 22, height: 22),
              ],
            ),
          ),
        ),
    ];
    return Semantics(
      label: context.tr(AppCopy.loadingCoursesLabel),
      child: embedded
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
              children: children,
            )
          : PageLayout(title: AppCopy.coursesTitle, children: children),
    );
  }
}
