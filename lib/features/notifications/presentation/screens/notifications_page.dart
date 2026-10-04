import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/account/presentation/account_cubit.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AccountContent(
        loadingKind: AccountSkeletonKind.notifications,
        builder: (context, state) {
          final unread = state.data.notifications
              .where(
                (item) => !state.data.readNotificationIds.contains(item.id),
              )
              .length;
          return ListView(
            children: [
              Stack(
                children: [
                  const AccountTopBar(
                    title: AppCopy.notificationsTitle,
                    notification: false,
                  ),
                  Positioned(
                    left: 17,
                    top: 48,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? context.colors.softBlue
                          : const Color(0xFFE9F4FF),
                      child: AppText(
                        '$unread',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (state.data.preview)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: AccountPreviewLabel(),
                ),
              if (state.data.notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: AppText(AppCopy.noNotificationsMessage)),
                ),
              for (final item in state.data.notifications)
                _NotificationCard(
                  item: item,
                  read: state.data.readNotificationIds.contains(item.id),
                  onTap: () => context
                      .read<AccountCubit>()
                      .markNotificationRead(accountUserId(context), item.id),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.read,
    required this.onTap,
  });
  final AccountNotification item;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 22),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.border, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: context.colors.surface,
            child: Icon(
              item.icon == 'offer'
                  ? Icons.local_offer_outlined
                  : Icons.campaign_rounded,
              color: accountAccent(context),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  item.title,
                  style: TextStyle(
                    color: read
                        ? context.colors.muted
                        : Theme.of(context).brightness == Brightness.dark
                        ? context.colors.secondary
                        : const Color(0xFF355AA3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppText(
                  item.dateLabel,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? context.colors.muted
                        : const Color(0xFFAAAAAA),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                AppText(
                  item.detail,
                  style: TextStyle(color: context.colors.primary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
