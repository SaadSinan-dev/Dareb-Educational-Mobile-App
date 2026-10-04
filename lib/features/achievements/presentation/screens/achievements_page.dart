import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';

import 'package:tamkeen2/features/profile/presentation/widgets/account_summary.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AccountContent(
        loadingKind: AccountSkeletonKind.achievements,
        builder: (context, state) => ListView(
          children: [
            const AccountTopBar(title: AppCopy.myAchievementsTitle),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: AccountSummary(data: state.data),
            ),
            const SizedBox(height: 24),
            if (state.data.achievements.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: AppText(AppCopy.noAchievementsMessage)),
              ),
            for (final achievement in state.data.achievements)
              _AchievementCard(data: achievement),
          ],
        ),
      ),
    ),
  );
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.data});
  final AccountAchievement data;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(18, 6, 18, 22),
    color: context.colors.surface,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 96,
                constraints: const BoxConstraints(minHeight: 65),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: accountAccent(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      data.title,
                      style: TextStyle(
                        color: context.colors.onBrand,
                        fontSize: 12,
                      ),
                    ),
                    Image.asset(data.iconAsset, height: 30),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LinearProgressIndicator(
                  value: data.subjectProgress,
                  minHeight: 6,
                  color: accountAccent(context),
                  backgroundColor: context.colors.border,
                ),
              ),
              const SizedBox(width: 10),
              AppText(
                '${(data.subjectProgress * 100).round()}%',
                style: TextStyle(color: context.colors.primary),
              ),
            ],
          ),
          const Divider(height: 28),
          _ProgressLine(
            label: AppCopy.pointsLabel,
            count: '${data.points}',
            total: '${data.pointsTotal}',
            value: data.pointsProgress,
            icon: Icons.stars_outlined,
          ),
          const SizedBox(height: 12),
          _ProgressLine(
            label: AppCopy.chaptersLabel,
            count: '${data.chapters}',
            total: '${data.chaptersTotal}',
            value: data.chaptersProgress,
            icon: Icons.view_module_outlined,
          ),
          const SizedBox(height: 12),
          _ProgressLine(
            label: AppCopy.lessonsLabel,
            count: '${data.lessons}',
            total: '${data.lessonsTotal}',
            value: data.lessonsProgress,
            icon: Icons.menu_book_outlined,
          ),
        ],
      ),
    ),
  );
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.count,
    required this.total,
    required this.value,
    required this.icon,
  });
  final String label, count, total;
  final double value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: accountAccent(context), size: 25),
      const SizedBox(width: 7),
      AppText(label),
      const SizedBox(width: 8),
      AppText(count, style: TextStyle(color: context.colors.primary)),
      const SizedBox(width: 7),
      Expanded(
        child: LinearProgressIndicator(
          value: value,
          minHeight: 6,
          color: accountAccent(context),
          backgroundColor: context.colors.border,
        ),
      ),
      const SizedBox(width: 7),
      AppText(total, style: TextStyle(color: context.colors.primary)),
    ],
  );
}
