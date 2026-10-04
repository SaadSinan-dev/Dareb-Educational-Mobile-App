import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/assessments/domain/assessment.dart';
import 'package:tamkeen2/features/assessments/domain/assessment_repository.dart';
import 'package:tamkeen2/features/assessments/presentation/exam_cubit.dart';

import 'package:tamkeen2/core/widgets/request_retry.dart';

class RemoteExamPage extends StatefulWidget {
  const RemoteExamPage({
    super.key,
    required this.examId,
    this.initial,
    this.resultOnly = false,
    this.repository,
  });
  final String examId;
  final RemoteAssessment? initial;
  final bool resultOnly;
  final AssessmentRepository? repository;
  @override
  State<RemoteExamPage> createState() => _RemoteExamPageState();
}

class _RemoteExamPageState extends State<RemoteExamPage> {
  late final ExamCubit _cubit = ExamCubit(
    widget.repository ?? context.read<AssessmentRepository>(),
  )..load(widget.examId, initial: widget.initial);
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ExamCubit, ExamState>(
    bloc: _cubit,
    builder: (context, state) {
      final exam = state.data;
      final results = widget.resultOnly || state.confirmed;
      return PageLayout(
        title: results
            ? AppCopy.resultTitle
            : exam?.title ?? AppCopy.quizzesTab,
        children: [
          if (state.status == RemoteStatus.loading || state.busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (state.error != null)
            RemoteRetry(
              message: state.error!,
              retry: () => _cubit.load(widget.examId),
            ),
          if (state.status == RemoteStatus.empty)
            const AppText(AppCopy.examMissing),
          if (exam != null && results) ...[
            Image.asset('assets/icons/quiz.png', height: 72),
            if (exam.correctAnswers != null)
              AppText(
                '${context.tr(AppCopy.correctAnswersLabel)}: ${exam.correctAnswers}',
                textAlign: TextAlign.center,
              ),
            if (exam.failedAnswers != null)
              AppText(
                '${context.tr(AppCopy.failedAnswersLabel)}: ${exam.failedAnswers}',
                textAlign: TextAlign.center,
              ),
          ],
          if (exam != null)
            for (final (index, question) in exam.questions.indexed)
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      '${index + 1}. ${question.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (results)
                      for (final answer in question.answers)
                        ListTile(
                          title: AppText(answer.title),
                          trailing: answer.correct == null
                              ? null
                              : Icon(
                                  answer.correct!
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  color: answer.correct!
                                      ? context.colors.primary
                                      : context.colors.error,
                                ),
                        )
                    else
                      RadioGroup<String>(
                        groupValue: state.answers[question.id],
                        onChanged: (value) {
                          if (value != null && !state.busy) {
                            _cubit.select(question.id, value);
                          }
                        },
                        child: Column(
                          children: [
                            for (final answer in question.answers)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: context.colors.border,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: RadioListTile<String>(
                                  value: answer.id,
                                  title: AppText(answer.title),
                                  enabled: !state.busy,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          if (exam != null && !results && exam.questions.isNotEmpty)
            FilledButton(
              onPressed:
                  state.busy || state.answers.length != exam.questions.length
                  ? null
                  : () => _cubit.submit(),
              child: const AppText(AppCopy.scoreLabel),
            ),
        ],
      );
    },
  );
}
