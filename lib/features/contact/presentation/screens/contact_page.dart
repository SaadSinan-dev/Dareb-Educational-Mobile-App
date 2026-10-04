import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/widgets/source_icon.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/contact/domain/contact_message.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/contact/presentation/contact_cubit.dart';
import 'package:tamkeen2/features/account/presentation/account_preview_mode.dart';
import 'package:tamkeen2/features/contact/presentation/widgets/remote_account_contact_info.dart';

import 'package:tamkeen2/features/profile/presentation/widgets/profile_modal.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key, this.contentRepository, this.previewMode});

  final AccountContentRepository? contentRepository;
  final bool? previewMode;

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  final _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.user;
    _name = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ContactCubit>().state;
    return ProfileModal(
      title: AppCopy.contactUsTitle,
      icon: Icons.support_agent_outlined,
      leadingIcon: SourceIcon(
        SourceIconName.contact,
        color: accountAccent(context),
        size: 28,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (!accountPreviewMode(context, widget.previewMode)) ...[
              RemoteAccountContactInfo(repository: widget.contentRepository),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: context.tr(AppCopy.firstNameLabel),
                      prefixIcon: SourceIcon(
                        SourceIconName.profileCircle,
                        size: 22,
                        color: accountAccent(context),
                      ),
                    ),
                    validator: (value) {
                      final error = AppValidators.name(value);
                      return error == null ? null : context.tr(error);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastName,
                    decoration: InputDecoration(
                      labelText: context.tr(AppCopy.lastNameLabel),
                      prefixIcon: SourceIcon(
                        SourceIconName.profileCircle,
                        size: 22,
                        color: accountAccent(context),
                      ),
                    ),
                    validator: (value) {
                      final error = AppValidators.name(value);
                      return error == null ? null : context.tr(error);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.tr(AppCopy.phoneNumberLabel),
                prefixIcon: SourceIcon(
                  SourceIconName.contactPhone,
                  size: 24,
                  color: accountAccent(context),
                ),
              ),
              validator: (value) {
                final error = AppValidators.phone(value);
                return error == null ? null : context.tr(error);
              },
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.tr(AppCopy.descriptionHint),
                alignLabelWithHint: true,
                prefixIcon: SizedBox(
                  height: 108,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SourceIcon(
                        SourceIconName.contactDescription,
                        color: accountAccent(context),
                        size: 23,
                      ),
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 42,
                  maxWidth: 42,
                ),
              ),
              validator: (value) {
                final error = AppValidators.contactMessage(value);
                return error == null ? null : context.tr(error);
              },
            ),
            const SizedBox(height: 14),
            if (state.actionMessage != null)
              AppText(
                state.actionMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: switch (state.actionStatus) {
                    ContactStatus.failure => accountError(context),
                    ContactStatus.success => context.colors.primary,
                    _ => context.colors.muted,
                  },
                ),
              ),
            const SizedBox(height: 16),
            ProfileModalActions(
              label: AppCopy.confirmAction,
              busy: state.actionStatus == ContactStatus.submitting,
              confirm: () {
                if (!_formKey.currentState!.validate()) return;
                context.read<ContactCubit>().submitContact(
                  ContactMessage(
                    name: _name.text,
                    lastName: _lastName.text,
                    phone: _phone.text,
                    description: _description.text,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
