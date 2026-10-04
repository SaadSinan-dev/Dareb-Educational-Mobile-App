import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/history/presentation/screens/remote_history_page.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';
import 'package:tamkeen2/core/widgets/segmented_tabs.dart';
import 'package:tamkeen2/features/assessments/presentation/widgets/assessment_list.dart';

class AssessmentsPage extends StatefulWidget {
  const AssessmentsPage({super.key, this.activities = false});
  final bool activities;
  @override
  State<AssessmentsPage> createState() => _AssessmentsPageState();
}

class _AssessmentsPageState extends State<AssessmentsPage> {
  late bool activities = widget.activities;
  @override
  Widget build(BuildContext context) {
    if (!context.read<CourseCubit>().demoMode) {
      return RemoteHistoryPage(activities: widget.activities);
    }
    final state = context.watch<CourseCubit>().state;
    return CatalogContent(
      state: state,
      child: PageLayout(
        title: AppCopy.myQuizzes,
        actions: [notificationAction(context)],
        children: [
          AppSearch(
            value: state.search,
            onChanged: context.read<CourseCubit>().search,
          ),
          SegmentedTabs(
            const [AppCopy.quizzesTab, AppCopy.dailyActivities],
            activities ? 1 : 0,
            (value) => setState(() => activities = value == 1),
          ),
          AssessmentList(courses: state.visibleCourses, activities: activities),
        ],
      ),
    );
  }
}
