import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/features/content/presentation/page_content_cubit.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';

/// Displays only verified CMS page content in normal mode.
class RemoteAccountPageContent extends StatefulWidget {
  const RemoteAccountPageContent({
    super.key,
    required this.kind,
    this.repository,
    this.centered = false,
  });

  final AccountPageKind kind;
  final AccountContentRepository? repository;
  final bool centered;

  @override
  State<RemoteAccountPageContent> createState() =>
      _RemoteAccountPageContentState();
}

class _RemoteAccountPageContentState extends State<RemoteAccountPageContent> {
  late final PageContentCubit _cubit = PageContentCubit(
    widget.repository ?? context.read<AccountContentRepository>(),
    widget.kind,
  )..load();
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PageContentCubit, ResourceState<String>>(
        bloc: _cubit,
        builder: (context, snapshot) {
          if (snapshot.status == ResourceStatus.loading) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.status == ResourceStatus.failure) {
            final error = snapshot.error;
            return _Message(
              message: error ?? AppCopy.accountLoadingFailed,
              onRetry: _cubit.load,
            );
          }
          final text = snapshot.data ?? '';
          if (text.isEmpty) {
            return _Message(
              message: AppCopy.pageContentEmpty,
              onRetry: _cubit.load,
            );
          }
          return SelectableText(
            text,
            textAlign: widget.centered ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: context.colors.ink,
              fontSize: 14,
              height: 1.65,
            ),
          );
        },
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(message, textAlign: TextAlign.center),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const AppText(AppCopy.retryAction),
          ),
      ],
    ),
  );
}
