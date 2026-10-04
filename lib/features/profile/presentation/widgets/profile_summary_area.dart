import 'dart:async';

import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/account/presentation/account_cubit.dart';
import 'package:tamkeen2/features/account/presentation/account_preview_mode.dart';

import 'package:tamkeen2/features/profile/presentation/widgets/account_summary.dart';

class ProfileSummaryArea extends StatefulWidget {
  const ProfileSummaryArea({super.key});

  @override
  State<ProfileSummaryArea> createState() => _ProfileSummaryAreaState();
}

class _ProfileSummaryAreaState extends State<ProfileSummaryArea> {
  Future<void> _changePhoto() async {
    final account = context.read<AccountCubit>();
    final userId = accountUserId(context);
    if (account.state.actionStatus == AccountActionStatus.submitting) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted || accountUserId(context) != userId) return;
      await account.updateImage(userId, bytes, file.name, file.mimeType);
      if (!mounted) return;
      final message = account.state.actionMessage;
      if (message != null) showAppMessage(context, message);
    } catch (_) {
      if (mounted) showAppMessage(context, AppCopy.unexpectedClientError);
    }
  }

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
      if (state.status == AccountStatus.ready) {
        return AccountSummary(
          data: state.data,
          onPhotoTap: state.data.preview ? null : _changePhoto,
          photoBusy: state.actionStatus == AccountActionStatus.submitting,
        );
      }
      if (state.status == AccountStatus.failure) {
        return Column(
          children: [
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
        );
      }
      return accountPreviewMode(context, null)
          ? const SizedBox(
              height: 130,
              child: Center(child: CircularProgressIndicator()),
            )
          : const AccountSummarySkeleton();
    },
  );
}
