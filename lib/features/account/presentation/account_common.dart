import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/account/presentation/account_cubit.dart';

const accountBlue = Color(0xFF5589F5);

Color accountAccent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? context.colors.secondary
    : accountBlue;

enum AccountSkeletonKind { profile, gallery, notifications, achievements }

class AccountSummarySkeleton extends StatelessWidget {
  const AccountSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr(AppCopy.loadingAccountLabel),
    child: Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Transform.translate(
            offset: Offset(0, -18),
            child: SkeletonBlock(width: 160, height: 160, radius: 80),
          ),
          Transform.translate(
            offset: Offset(0, -10),
            child: SkeletonBlock(width: 150, height: 22),
          ),
          Divider(color: context.colors.border),
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                const Expanded(
                  child: Column(
                    children: [
                      SkeletonBlock(width: 28, height: 20),
                      SizedBox(height: 5),
                      SkeletonBlock(width: 42, height: 10),
                    ],
                  ),
                ),
                if (i != 4)
                  Container(width: 1, height: 38, color: context.colors.border),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

class AccountGalleryGridSkeleton extends StatelessWidget {
  const AccountGalleryGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr(AppCopy.loadingAccountLabel),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: LayoutBuilder(
        builder: (context, constraints) => GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: constraints.maxWidth >= 600 ? 3 : 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 16,
          childAspectRatio: .82,
          children: [
            for (var i = 0; i < 6; i++)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border.all(color: context.colors.border, width: 1.4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonBlock(width: 42, height: 42, radius: 12),
                    SizedBox(height: 10),
                    SkeletonBlock(height: 15),
                    SizedBox(height: 8),
                    SkeletonBlock(width: 85, height: 11),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

String accountUserId(BuildContext context) =>
    context.read<AuthCubit>().state.user?.id ?? 'preview-guest';

void accountBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.profile);
  }
}

class AccountContent extends StatefulWidget {
  const AccountContent({
    super.key,
    required this.builder,
    this.loadingKind = AccountSkeletonKind.profile,
  });
  final Widget Function(BuildContext, AccountState) builder;
  final AccountSkeletonKind loadingKind;

  @override
  State<AccountContent> createState() => _AccountContentState();
}

class _AccountContentState extends State<AccountContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<AccountCubit>();
      if (cubit.state.status == AccountStatus.initial) {
        cubit.load(accountUserId(context));
      }
    });
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AccountCubit, AccountState>(
    builder: (context, state) {
      if (state.status == AccountStatus.initial ||
          state.status == AccountStatus.loading) {
        return _AccountSkeleton(kind: widget.loadingKind);
      }
      if (state.status == AccountStatus.failure) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  color: accountAccent(context),
                  size: 46,
                ),
                const SizedBox(height: 12),
                AppText(
                  state.error ?? AppCopy.accountLoadingFailed,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () =>
                      context.read<AccountCubit>().load(accountUserId(context)),
                  child: const AppText(AppCopy.retryAction),
                ),
              ],
            ),
          ),
        );
      }
      return widget.builder(context, state);
    },
  );
}

class _AccountSkeleton extends StatelessWidget {
  const _AccountSkeleton({required this.kind});
  final AccountSkeletonKind kind;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr(AppCopy.loadingAccountLabel),
    child: ListView(
      children: [
        if (kind != AccountSkeletonKind.gallery)
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
          ),
        if (kind == AccountSkeletonKind.gallery)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
            child: LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: constraints.maxWidth >= 600 ? 3 : 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 16,
                childAspectRatio: .82,
                children: [
                  for (var i = 0; i < 6; i++)
                    const Column(
                      children: [
                        Expanded(
                          child: SkeletonBlock(
                            height: double.infinity,
                            radius: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        SkeletonBlock(height: 15),
                      ],
                    ),
                ],
              ),
            ),
          ),
        if (kind == AccountSkeletonKind.notifications)
          for (var i = 0; i < 5; i++)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 24, 18, 10),
              child: Row(
                children: [
                  SkeletonBlock(width: 58, height: 58, radius: 29),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBlock(height: 15),
                        SizedBox(height: 10),
                        SkeletonBlock(height: 13),
                        SizedBox(height: 8),
                        SkeletonBlock(width: 110, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        if (kind == AccountSkeletonKind.profile ||
            kind == AccountSkeletonKind.achievements) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 28, 18, 20),
            child: Row(
              children: [
                SkeletonBlock(width: 88, height: 88, radius: 44),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(height: 20),
                      SizedBox(height: 12),
                      SkeletonBlock(width: 112, height: 15),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(child: SkeletonBlock(height: 60)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBlock(height: 60)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBlock(height: 60)),
              ],
            ),
          ),
          if (kind == AccountSkeletonKind.profile)
            for (var i = 0; i < 5; i++)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 24, 18, 0),
                child: Row(
                  children: [
                    SkeletonBlock(width: 24, height: 24),
                    SizedBox(width: 14),
                    Expanded(child: SkeletonBlock(height: 16)),
                    SizedBox(width: 35),
                    SkeletonBlock(width: 18, height: 18),
                  ],
                ),
              ),
          if (kind == AccountSkeletonKind.achievements)
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 24, 18, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: SkeletonBlock(height: 18)),
                        SizedBox(width: 14),
                        SkeletonBlock(width: 74, height: 60),
                      ],
                    ),
                    SizedBox(height: 14),
                    SkeletonBlock(height: 10),
                    SizedBox(height: 12),
                    SkeletonBlock(height: 10),
                  ],
                ),
              ),
        ],
      ],
    ),
  );
}

class AccountTopBar extends StatelessWidget {
  const AccountTopBar({
    super.key,
    required this.title,
    this.back = true,
    this.notification = true,
  });
  final String title;
  final bool back;
  final bool notification;

  @override
  Widget build(BuildContext context) => Container(
    height: 110,
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 15),
    decoration: BoxDecoration(
      color: context.colors.primary,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
    ),
    child: Row(
      textDirection: TextDirection.ltr,
      children: [
        if (notification)
          IconButton(
            onPressed: () => context.push(AppRoutes.notifications),
            style: IconButton.styleFrom(
              backgroundColor: accountAccent(context),
              foregroundColor: context.colors.onBrand,
            ),
            icon: Image.asset(
              'assets/icons/header_notification.png',
              width: 37,
              height: 37,
            ),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: AppText(
            title,
            style: TextStyle(
              color: context.colors.onBrand,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        back
            ? IconButton(
                onPressed: () => accountBack(context),
                icon: Icon(Icons.arrow_back, color: context.colors.onBrand),
              )
            : SizedBox(
                width: 48,
                height: 48,
                child: Image.asset(
                  'assets/images/logo_white.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.auto_stories_outlined,
                    color: context.colors.onBrand,
                  ),
                ),
              ),
      ],
    ),
  );
}

class AccountPhoto extends StatelessWidget {
  const AccountPhoto(this.asset, {super.key, this.fit = BoxFit.cover});
  final String asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    fit: fit,
    errorBuilder: (_, _, _) => Container(
      color: context.colors.border,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: context.colors.muted),
    ),
  );
}

class AccountPreviewLabel extends StatelessWidget {
  const AccountPreviewLabel({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: AppText(
      AppCopy.demoContentLabel,
      textAlign: TextAlign.center,
      style: TextStyle(color: context.colors.muted, fontSize: 11),
    ),
  );
}
