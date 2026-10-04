import 'package:tamkeen2/features/assessments/presentation/preview_quiz_cubit.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';
import 'package:tamkeen2/features/assessments/presentation/widgets/question_card.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.courseId, this.activity = false});
  final String courseId;
  final bool activity;
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  @override
  void initState() {
    super.initState();
    context.read<PreviewQuizCubit>().startQuiz(widget.courseId);
  }

  @override
  void didUpdateWidget(covariant QuizPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId) {
      context.read<PreviewQuizCubit>().startQuiz(widget.courseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PreviewQuizCubit>();
    final state = cubit.state;
    return PageLayout(
      title: widget.activity
          ? AppCopy.dailyActivity
          : AppCopy.format(AppCopy.subjectQuiz, [
              context.read<CourseCubit>().course(widget.courseId)?.category ??
                  '',
            ]),
      children: [
        if (state.quizStatus == QuizStatus.initial ||
            state.quizStatus == QuizStatus.loading)
          for (var i = 0; i < 2; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: SurfaceCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        SkeletonBlock(width: 34, height: 34, radius: 17),
                        SizedBox(width: 12),
                        Expanded(child: SkeletonBlock(height: 17)),
                      ],
                    ),
                    SizedBox(height: 24),
                    SkeletonBlock(height: 82, radius: 10),
                    SizedBox(height: 20),
                    SkeletonBlock(height: 48, radius: 10),
                    SizedBox(height: 10),
                    SkeletonBlock(height: 48, radius: 10),
                    SizedBox(height: 10),
                    SkeletonBlock(height: 48, radius: 10),
                  ],
                ),
              ),
            )
        else if (state.quizStatus == QuizStatus.failure) ...[
          AppText(state.operationError ?? AppCopy.questionsLoadFailed),
          TextButton(
            onPressed: () => cubit.startQuiz(widget.courseId),
            child: AppText(AppCopy.retryAction),
          ),
        ] else if (state.quizSubmitted) ...[
          learningSectionGap,
          Image.asset('assets/icons/result_badge.png', width: 170, height: 135),
          learningSectionGap,
          AppText(
            AppCopy.quizCompleted,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          AppText(AppCopy.reviewAndKeepLearning, textAlign: TextAlign.center),
          learningSectionGap,
          AppText(
            '${(state.score / state.questions.length * 100).round()}%',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 70, color: context.colors.secondary),
          ),
          learningSectionGap,
          Row(
            children: [
              for (final entry in [
                (AppCopy.questionCountLabel, state.questions.length),
                (AppCopy.correctAnswers, state.score),
                (
                  AppCopy.incorrectAnswers,
                  state.questions.length - state.score,
                ),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SurfaceCard(
                      child: Column(
                        children: [
                          AppText(
                            '${entry.$2}',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppText(entry.$1, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          learningSectionGap,
          FilledButton(
            onPressed: () => context.push(AppRoutes.quizReview),
            child: AppText(AppCopy.checkAnswers),
          ),
          learningSectionGap,
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: AppText(AppCopy.backToHome),
          ),
        ] else ...[
          learningSectionGap,
          for (var q = 0; q < state.questions.length; q++) ...[
            QuestionCard(
              question: state.questions[q],
              number: q + 1,
              answer: state.quizAnswers[q],
              onAnswer: (answer) => cubit.answerQuestion(q, answer),
            ),
            learningSectionGap,
          ],
          FilledButton(
            onPressed: state.quizAnswers.length == state.questions.length
                ? cubit.submitQuiz
                : null,
            child: AppText(AppCopy.scoreLabel),
          ),
        ],
      ],
    );
  }
}
