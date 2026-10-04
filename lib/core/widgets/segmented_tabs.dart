import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs(this.labels, this.selected, this.onChanged, {super.key});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Semantics(
                selected: i == selected,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onChanged(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: i == selected
                          ? context.colors.primary
                          : context.colors.tabIdle,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: AppText(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: i == selected
                            ? context.colors.onBrand
                            : context.colors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
