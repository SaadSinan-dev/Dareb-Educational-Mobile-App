import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/assessments/domain/assessment_repository.dart';
import 'package:tamkeen2/features/history/presentation/history_cubit.dart';

import 'package:tamkeen2/core/widgets/request_retry.dart';
import 'package:tamkeen2/features/assessments/presentation/widgets/remote_assessment_cards.dart';

class RemoteHistoryList extends StatefulWidget {
  const RemoteHistoryList({super.key, this.activities = false});
  final bool activities;
  @override
  State<RemoteHistoryList> createState() => _RemoteHistoryListState();
}

class _RemoteHistoryListState extends State<RemoteHistoryList> {
  late final HistoryCubit _cubit = HistoryCubit(
    context.read<AssessmentRepository>(),
  )..load(activities: widget.activities);
  @override
  void didUpdateWidget(RemoteHistoryList old) {
    super.didUpdateWidget(old);
    if (widget.activities != old.activities) {
      _cubit.load(activities: widget.activities);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
    bloc: _cubit,
    builder: (context, state) => Column(
      children: [
        if (state.status == RemoteStatus.loading)
          const Center(child: CircularProgressIndicator()),
        if (state.error != null)
          RemoteRetry(message: state.error!, retry: () => _cubit.load()),
        if (state.status == RemoteStatus.empty)
          const AppText(AppCopy.noHistory),
        if (state.data != null)
          RemoteAssessmentCards(
            records: state.data!,
            activities: widget.activities,
            results: true,
          ),
      ],
    ),
  );
}
