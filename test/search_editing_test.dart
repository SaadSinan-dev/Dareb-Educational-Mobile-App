import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';

void main() {
  testWidgets(
    'search keeps Arabic composing text selection and focus across rebuilds',
    (tester) async {
      var text = '';
      var submitted = '';
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: AppSearch(
                    value: text,
                    onChanged: (value) => setState(() => text = value),
                    onSubmitted: (value) => submitted = value,
                  ),
                ),
              );
            },
          ),
        ),
      );
      final field = find.byType(TextFormField);
      await tester.showKeyboard(field);
      const edit = TextEditingValue(
        text: 'العربية English ١٢٣ ',
        selection: TextSelection.collapsed(offset: 7),
        composing: TextRange(start: 0, end: 7),
      );
      tester.testTextInput.updateEditingValue(edit);
      await tester.pump();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.value, edit);
      expect(editable.focusNode.hasFocus, isTrue);
      expect(editable.textDirection, TextDirection.rtl);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted, edit.text);
      rebuild(() => text = 'بحث محفوظ');
      await tester.pump();
      expect(editable.controller.text, 'بحث محفوظ');
      expect(tester.takeException(), isNull);
    },
  );
}
