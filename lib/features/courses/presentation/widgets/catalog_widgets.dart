import 'package:tamkeen2/features/courses/presentation/widgets/course_cards.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

const learningSectionGap = SizedBox(height: 20);

class CatalogContent extends StatelessWidget {
  const CatalogContent({
    super.key,
    required this.state,
    required this.child,
    this.onRefresh,
    this.title,
  });
  final String? title;
  final CourseState state;
  final Widget child;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final content = LoadingContent(
      state: state,
      embedded: title != null,
      child: RefreshIndicator(
        onRefresh: onRefresh ?? context.read<CourseCubit>().load,
        child: child,
      ),
    );
    return title == null
        ? content
        : PageLayout(title: title!, back: false, body: content);
  }
}

void showLearningOperation(BuildContext context) {
  final state = context.read<CourseCubit>().state;
  showAppMessage(
    context,
    state.operationError ??
        state.operationMessage ??
        AppCopy.serviceCurrentlyUnavailable,
  );
}

Course? findCourse(BuildContext context, String id) =>
    context.read<CourseCubit>().course(id);

Widget notificationAction(BuildContext context) => HeaderNotificationAction(
  onPressed: () => context.push(AppRoutes.notifications),
);

class MissingCourse extends StatelessWidget {
  const MissingCourse({super.key, required this.state});
  final CourseState state;
  @override
  Widget build(BuildContext context) => PageLayout(
    title: AppCopy.courseDetails,
    children: [
      if (state.status == LoadStatus.loading)
        const CourseDetailSkeleton()
      else ...[
        AppText(state.error ?? AppCopy.courseUnavailableTitle),
        TextButton(
          onPressed: context.read<CourseCubit>().load,
          child: AppText(AppCopy.retryAction),
        ),
      ],
    ],
  );
}

class CourseDetailSkeleton extends StatelessWidget {
  const CourseDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr(AppCopy.loadingCoursesLabel),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBlock(height: 210, radius: 16),
        SizedBox(height: 18),
        SkeletonBlock(width: 160, height: 22),
        SizedBox(height: 12),
        SkeletonBlock(height: 13),
        SizedBox(height: 8),
        SkeletonBlock(width: 210, height: 13),
        SizedBox(height: 24),
        SkeletonBlock(width: 120, height: 19),
        SizedBox(height: 12),
        SkeletonBlock(height: 70, radius: 12),
        SizedBox(height: 12),
        SkeletonBlock(height: 70, radius: 12),
      ],
    ),
  );
}
