import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/features/contact/presentation/contact_info_cubit.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';

class RemoteAccountContactInfo extends StatefulWidget {
  const RemoteAccountContactInfo({super.key, this.repository});

  final AccountContentRepository? repository;

  @override
  State<RemoteAccountContactInfo> createState() =>
      _RemoteAccountContactInfoState();
}

class _RemoteAccountContactInfoState extends State<RemoteAccountContactInfo> {
  late final ContactInfoCubit _cubit = ContactInfoCubit(
    widget.repository ?? context.read<AccountContentRepository>(),
  )..load();
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ContactInfoCubit, ResourceState<AccountContactInfo>>(
        bloc: _cubit,
        builder: (context, snapshot) {
          if (snapshot.status == ResourceStatus.loading) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.status == ResourceStatus.failure) {
            return Column(
              children: [
                AppText(
                  snapshot.error ?? AppCopy.accountLoadingFailed,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: _cubit.load,
                  child: const AppText(AppCopy.retryAction),
                ),
              ],
            );
          }
          final info = snapshot.data!;
          final email = info.email.trim();
          final phone = info.phone.trim();
          if (email.isEmpty && phone.isEmpty) {
            return const AppText(
              AppCopy.pageContentEmpty,
              textAlign: TextAlign.center,
            );
          }
          return Column(
            children: [
              if (email.isNotEmpty)
                ListTile(
                  leading: Icon(
                    Icons.email_outlined,
                    color: context.colors.primary,
                  ),
                  title: SelectableText(
                    email,
                    style: TextStyle(color: context.colors.ink),
                  ),
                ),
              if (phone.isNotEmpty)
                ListTile(
                  leading: Icon(
                    Icons.phone_outlined,
                    color: context.colors.primary,
                  ),
                  title: SelectableText(
                    phone,
                    style: TextStyle(color: context.colors.ink),
                  ),
                ),
            ],
          );
        },
      );
}
