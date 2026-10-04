import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

import 'package:flutter/material.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('session-initializing'),
    backgroundColor: light
        ? context.colors.background
        : context.colors.splashStart,
    body: DecoratedBox(
      decoration: light
          ? const BoxDecoration()
          : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [context.colors.splashStart, context.colors.splashEnd],
              ),
            ),
      child: SizedBox.expand(
        child: SafeArea(
          child: Center(
            child: Image.asset(
              light && Theme.of(context).brightness == Brightness.light
                  ? 'assets/images/logo_color.png'
                  : 'assets/images/logo_white.png',
              width: 205,
              height: 205,
              fit: BoxFit.contain,
              semanticLabel: context.tr(AppCopy.appLogoLabel),
              color: light ? null : context.colors.onBrand,
            ),
          ),
        ),
      ),
    ),
  );
}
