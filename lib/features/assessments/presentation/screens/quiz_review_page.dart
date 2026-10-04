import 'package:tamkeen2/features/assessments/presentation/preview_quiz_cubit.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';

class QuizReviewPage extends StatelessWidget {
  const QuizReviewPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PreviewQuizCubit>().state;
    return PageLayout(
      title: AppCopy.quizResults,
      children: [
        if (!state.quizSubmitted)
          AppText(AppCopy.completeQuizBeforeReview)
        else ...[
          const SectionTitle(AppCopy.detailedReview),
          for (var i = 0; i < state.questions.length; i++) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        state.quizAnswers[i] == state.questions[i].correctIndex
                            ? Icons.check_circle
                            : Icons.cancel,
                        color:
                            state.quizAnswers[i] ==
                                state.questions[i].correctIndex
                            ? context.colors.primary
                            : context.colors.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppText(
                          '${i + 1}. ${state.questions[i].title}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  learningSectionGap,
                  AppText(
                    AppCopy.format(AppCopy.yourAnswer, [
                      state.questions[i].answers[state.quizAnswers[i]!],
                    ]),
                    style: TextStyle(
                      color:
                          state.quizAnswers[i] ==
                              state.questions[i].correctIndex
                          ? context.colors.primary
                          : context.colors.error,
                    ),
                  ),
                  if (state.quizAnswers[i] != state.questions[i].correctIndex)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AppText(
                        AppCopy.format(AppCopy.correctAnswer, [
                          state.questions[i].answers[state
                              .questions[i]
                              .correctIndex],
                        ]),
                        style: TextStyle(color: context.colors.primary),
                      ),
                    ),
                ],
              ),
            ),
            learningSectionGap,
          ],
        ],
        FilledButton(
          onPressed: () => context.go(AppRoutes.home),
          child: AppText(AppCopy.backToHome),
        ),
      ],
    );
  }
}
