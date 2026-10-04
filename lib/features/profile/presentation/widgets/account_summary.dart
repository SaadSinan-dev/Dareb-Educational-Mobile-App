import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';

class AccountSummary extends StatelessWidget {
  const AccountSummary({
    super.key,
    required this.data,
    this.onPhotoTap,
    this.photoBusy = false,
  });
  final AccountData data;
  final VoidCallback? onPhotoTap;
  final bool photoBusy;

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthCubit>().state.user;
    final name =
        data.profile?.displayName ??
        authUser?.displayName ??
        AppCopy.profileTitle;
    final stats = [
      (data.summary?.badges, AppCopy.badgesLabel),
      (data.summary?.lessons, AppCopy.lessonsLabel),
      (data.summary?.courses, AppCopy.coursesTitle),
      (data.summary?.points, AppCopy.pointsLabel),
      (data.summary?.chapters, AppCopy.chaptersLabel),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Transform.translate(
            offset: const Offset(0, -18),
            child: SizedBox(
              width: 190,
              height: 166,
              child: Semantics(
                button: onPhotoTap != null,
                label: onPhotoTap == null
                    ? null
                    : context.tr(AppCopy.changeProfilePhoto),
                child: GestureDetector(
                  onTap: photoBusy ? null : onPhotoTap,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const AccountPhoto(
                        'assets/images/avatar.png',
                        fit: BoxFit.contain,
                      ),
                      if (photoBusy)
                        ColoredBox(
                          color: Colors.black38,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: context.colors.onBrand,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: AppText(
              name,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: context.colors.ink,
              ),
            ),
          ),
          if (data.preview) const AccountPreviewLabel(),
          Divider(color: context.colors.border),
          Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      AppText(
                        stats[i].$1?.toString() ?? '—',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppText(
                        stats[i].$2,
                        style: TextStyle(
                          color: context.colors.ink,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != stats.length - 1)
                  Container(width: 1, height: 38, color: context.colors.border),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
