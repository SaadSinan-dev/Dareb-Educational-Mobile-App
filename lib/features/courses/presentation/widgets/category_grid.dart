import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/course_artwork.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.onSelect,
    this.horizontal = false,
  });
  final List<String> categories;
  final ValueChanged<String> onSelect;
  final bool horizontal;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final items = <Widget>[
        for (final category in categories)
          SizedBox(
            width: horizontal ? 127 : (constraints.maxWidth - 20) / 3,
            child: InkWell(
              onTap: () => onSelect(category),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.secondary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: AppText(
                      category,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.onBrand),
                    ),
                  ),
                  const SizedBox(height: 8),
                  courseAsset(
                    'icons/${subjectAssetName(category)}',
                    height: 68,
                  ),
                ],
              ),
            ),
          ),
      ];
      if (horizontal) {
        return SingleChildScrollView(
          key: const ValueKey('home-materials-scroll'),
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index != 0) const SizedBox(width: 10),
                items[index],
              ],
            ],
          ),
        );
      }
      return Wrap(spacing: 10, runSpacing: 22, children: items);
    },
  );
}
