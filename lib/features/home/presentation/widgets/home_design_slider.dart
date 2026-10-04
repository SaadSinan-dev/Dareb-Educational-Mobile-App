import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

class HomeDesignSlider extends StatelessWidget {
  const HomeDesignSlider({super.key, required this.onAccountTap});
  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = constraints.maxWidth / 398;
      final textWidth = constraints.maxWidth * .44 - 16;
      final text = context
          .tr(AppCopy.excellenceStartsHere)
          .replaceAll(RegExp(r'\n\s+'), '\n');
      final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: context.colors.onBrand,
        fontSize: 14,
        height: 1.5,
      );
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: textWidth);
      final buttonPainter = TextPainter(
        text: TextSpan(
          text: context.tr(AppCopy.checkAccountNow),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: textWidth - 16);
      final buttonHeight = math.max(48.0, buttonPainter.height + 16);
      final backgroundHeight = math.max(
        146 * scale,
        painter.height + buttonHeight + 48,
      );
      buttonPainter.dispose();
      painter.dispose();
      final overlap = 27 * scale;
      return Column(
        children: [
          SizedBox(
            height: math.max(176 * scale, backgroundHeight + overlap),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: overlap,
                  left: 5 * scale,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        begin: AlignmentDirectional.centerEnd,
                        end: AlignmentDirectional.centerStart,
                        colors: [Color(0xFF4196A0), Color(0xFF2CBABE)],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  width: 201 * scale,
                  height: 176 * scale,
                  child: Image.asset(
                    'assets/illustrations/graduates.png',
                    fit: BoxFit.contain,
                    semanticLabel: context.tr(AppCopy.featuredCourses),
                  ),
                ),
                PositionedDirectional(
                  top: overlap,
                  start: 16,
                  bottom: 0,
                  width: textWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(text, textAlign: TextAlign.center, style: style),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onAccountTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.colors.onBrand,
                            backgroundColor: Colors.white.withValues(
                              alpha: .35,
                            ),
                            side: BorderSide(color: context.colors.onBrand),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            context.tr(AppCopy.checkAccountNow),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.ltr,
            children: [
              for (var index = 0; index < 3; index++)
                Container(
                  width: index == 0 ? 32 : 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? context.colors.secondary
                        : context.colors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}
