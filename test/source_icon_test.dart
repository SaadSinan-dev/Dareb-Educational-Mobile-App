import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/widgets/source_icon.dart';

void main() {
  testWidgets('field hit area does not enlarge the source glyph', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 48,
            child: SourceIcon(SourceIconName.profileCircle, size: 22),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(SvgPicture)), const Size(22, 22));
    expect(tester.takeException(), isNull);
  });
}
