import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/assessments/domain/assessment.dart';

class RemoteAssessmentCards extends StatelessWidget {
  const RemoteAssessmentCards({
    super.key,
    required this.records,
    this.activities = false,
    this.results = false,
  });
  final List<RemoteAssessment> records;
  final bool activities, results;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final record in records)
        SurfaceCard(
          child: InkWell(
            onTap: () => context.push(
              '/exam/${record.id}${results ? '?result=true' : ''}',
              extra: record,
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/${activities ? 'activity' : 'quiz'}.png',
                  width: 55,
                  height: 64,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        record.title,
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 17,
                        ),
                      ),
                      if (record.professor != null)
                        AppText(
                          record.professor!,
                          style: TextStyle(color: context.colors.muted),
                        ),
                      if (record.questionCount != null)
                        AppText(
                          '${record.questionCount}',
                          style: TextStyle(color: context.colors.primary),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: context.colors.secondary,
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
