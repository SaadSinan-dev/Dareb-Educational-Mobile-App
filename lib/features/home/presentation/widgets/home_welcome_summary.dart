import 'package:flutter/material.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_artwork.dart';

class HomeWelcomeSummary extends StatelessWidget {
  const HomeWelcomeSummary({
    super.key,
    required this.displayName,
    required this.courseCount,
    required this.completedLessons,
    required this.onAchievements,
  });
  final String displayName;
  final int courseCount, completedLessons;
  final VoidCallback onAchievements;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 30, 16, 18),
    decoration: BoxDecoration(
      color: context.colors.primary,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
    ),
    child: Row(
      children: [
        ClipOval(
          child: courseAsset(
            'images/avatar',
            height: 72,
            width: 72,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                AppCopy.format(AppCopy.welcomeBackName, [displayName]),
                style: TextStyle(
                  color: context.colors.onBrand,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              AppText(
                AppCopy.format(AppCopy.coursesCompletedLessons, [
                  courseCount,
                  completedLessons,
                ]),
                style: TextStyle(color: context.colors.onBrand, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: context.tr(AppCopy.myAchievementsTitle),
          onPressed: onAchievements,
          icon: Icon(
            Icons.workspace_premium_outlined,
            color: context.colors.onBrand,
          ),
        ),
      ],
    ),
  );
}
