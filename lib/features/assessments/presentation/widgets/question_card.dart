import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.number,
    required this.answer,
    required this.onAnswer,
  });
  final QuizQuestion question;
  final int number;
  final int? answer;
  final ValueChanged<int> onAnswer;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: context.colors.primary.withValues(alpha: .12),
              child: AppText('$number'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                question.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        learningSectionGap,
        if (question.expression != null) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppText(
              question.expression!,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          learningSectionGap,
        ],
        RadioGroup<int>(
          groupValue: answer,
          onChanged: (value) {
            if (value != null) onAnswer(value);
          },
          child: Column(
            children: [
              for (var i = 0; i < question.answers.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: answer == i
                        ? context.colors.primary.withValues(alpha: .09)
                        : context.colors.surface,
                    border: Border.all(
                      color: answer == i
                          ? context.colors.primary
                          : context.colors.border,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RadioListTile<int>(
                    value: i,
                    title: AppText(question.answers[i]),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
