import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/assessments/domain/assessment_repository.dart';
import 'package:tamkeen2/features/history/presentation/history_cubit.dart';

import 'package:tamkeen2/core/widgets/request_retry.dart';
import 'package:tamkeen2/features/assessments/presentation/widgets/remote_assessment_cards.dart';

class RemoteHistoryPage extends StatefulWidget {
  const RemoteHistoryPage({
    super.key,
    this.activities = false,
    this.repository,
  });
  final bool activities;
  final AssessmentRepository? repository;
  @override
  State<RemoteHistoryPage> createState() => _RemoteHistoryPageState();
}

class _RemoteHistoryPageState extends State<RemoteHistoryPage> {
  late final HistoryCubit _cubit = HistoryCubit(
    widget.repository ?? context.read<AssessmentRepository>(),
  )..load(activities: widget.activities);
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
    bloc: _cubit,
    builder: (context, state) => PageLayout(
      title: AppCopy.myQuizzes,
      children: [
        Row(
          children: [
            for (final (index, label) in [
              AppCopy.quizzesTab,
              AppCopy.dailyActivities,
            ].indexed)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 10,
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _cubit.activities == (index == 1)
                          ? context.colors.primary
                          : context.colors.muted,
                    ),
                    onPressed: () => _cubit.load(activities: index == 1),
                    child: AppText(label),
                  ),
                ),
              ),
          ],
        ),
        if (state.status == RemoteStatus.loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (state.error != null)
          RemoteRetry(message: state.error!, retry: () => _cubit.load()),
        if (state.status == RemoteStatus.empty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: AppText(AppCopy.noHistory, textAlign: TextAlign.center),
          ),
        if (state.data != null)
          RemoteAssessmentCards(
            records: state.data!,
            activities: _cubit.activities,
            results: true,
          ),
      ],
    ),
  );
}

/// Embedded history panels use the same authenticated API as the history page.
