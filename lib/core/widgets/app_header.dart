import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

/// The reference page header. Routing and feature state belong to its caller.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: context.colors.onBrand,
    );
    // Measure the existing font metrics; large text can grow without clipping.
    final titleMetrics = TextPainter(
      text: TextSpan(
        text: 'أبAg',
        style: DefaultTextStyle.of(context).style.merge(titleStyle),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final rowHeight = math.max(48.0, titleMetrics.height);
    titleMetrics.dispose();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child:
                  leading ??
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      context.colors.onBrand,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/logo_white.png',
                      width: 48,
                      height: 48,
                      semanticLabel: context.tr(AppCopy.appName),
                    ),
                  ),
            ),
            Expanded(
              child: AppText(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            IconTheme(
              data: IconThemeData(color: context.colors.onBrand),
              child: actions.isEmpty
                  ? const SizedBox(width: 48)
                  : Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderNotificationAction extends StatelessWidget {
  const HeaderNotificationAction({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.tr(AppCopy.notificationsTitle),
    onPressed: onPressed,
    icon: Image.asset(
      'assets/icons/header_notification.png',
      width: 37,
      height: 37,
    ),
  );
}
