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

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.courseId});
  final String courseId;
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int? payment;
  bool confirmed = false;
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CourseCubit>();
    final course = cubit.course(widget.courseId);
    final isPlan =
        widget.courseId == 'plan-year' || widget.courseId == 'plan-free';
    if (course == null && !isPlan) return MissingCourse(state: cubit.state);
    final title =
        course?.title ??
        (widget.courseId == 'plan-year' ? AppCopy.oneYear : AppCopy.freeLabel);
    final price = course?.price ?? (widget.courseId == 'plan-year' ? 55000 : 0);
    return PageLayout(
      title: AppCopy.completePurchase,
      actions: [notificationAction(context)],
      children: [
        if (confirmed) ...[
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: context.colors.primary,
          ),
          learningSectionGap,
          AppText(
            AppCopy.previewActivated,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
          AppText(AppCopy.noPaymentProcessed, textAlign: TextAlign.center),
          learningSectionGap,
          FilledButton(
            onPressed: () => context.go(
              course == null
                  ? AppRoutes.myLearning
                  : AppRoutes.detail(course.id),
            ),
            child: AppText(AppCopy.continueLearning),
          ),
        ] else ...[
          const SectionTitle(AppCopy.choosePaymentMethod),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OutlinedButton(
                onPressed: () => setState(() => payment = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        i == 2
                            ? Icons.payments_outlined
                            : Icons.account_balance_outlined,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppText(
                          const [
                            AppCopy.paymentAlHaram,
                            AppCopy.paymentAlFouad,
                            AppCopy.paymentCashWithAdmin,
                          ][i],
                        ),
                      ),
                      Icon(
                        payment == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SectionTitle(AppCopy.paymentAccount),
          AppText(title),
          learningSectionGap,
          Row(
            children: [
              const Expanded(child: AppText(AppCopy.grandTotalLabel)),
              AppText(
                AppCopy.format(AppCopy.priceInSyrianPounds, [price]),
                style: TextStyle(color: context.colors.primary, fontSize: 20),
              ),
            ],
          ),
          learningSectionGap,
          if (cubit.demoMode) AppText(AppCopy.previewPaymentNotice),
          if (cubit.state.operationError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AppText(
                cubit.state.operationError!,
                style: TextStyle(color: context.colors.error),
              ),
            ),
          FilledButton(
            onPressed: payment == null
                ? null
                : () {
                    final success = isPlan
                        ? cubit.purchasePlan(widget.courseId)
                        : cubit.purchase(widget.courseId);
                    if (success) {
                      setState(() => confirmed = true);
                    } else {
                      showLearningOperation(context);
                    }
                  },
            child: AppText(
              cubit.demoMode
                  ? AppCopy.confirmPreview
                  : AppCopy.completePurchase,
            ),
          ),
        ],
      ],
    );
  }
}
