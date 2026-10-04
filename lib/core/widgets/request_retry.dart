import 'package:flutter/material.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

class RemoteRetry extends StatelessWidget {
  const RemoteRetry({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      children: [
        AppText(message, textAlign: TextAlign.center),
        TextButton(onPressed: retry, child: const AppText(AppCopy.retryAction)),
      ],
    ),
  );
}
