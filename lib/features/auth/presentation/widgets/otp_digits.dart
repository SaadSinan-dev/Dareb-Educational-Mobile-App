import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tamkeen2/features/auth/domain/auth_input.dart';

class OtpDigits extends StatefulWidget {
  const OtpDigits({super.key});

  @override
  State<OtpDigits> createState() => OtpDigitsState();
}

class OtpDigitsState extends State<OtpDigits> {
  final _digits = List.generate(4, (_) => TextEditingController());
  final _focus = List.generate(4, (_) => FocusNode());

  String get code => _digits.map((controller) => controller.text).join();

  void clear() {
    for (final controller in _digits) {
      controller.clear();
    }
  }

  @override
  void dispose() {
    for (final controller in _digits) {
      controller.dispose();
    }
    for (final focus in _focus) {
      focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = ((constraints.maxWidth - 24) / 4).clamp(0.0, 62.0);
      return Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          4,
          (index) => Padding(
            padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
            child: SizedBox(
              width: width,
              height: 62,
              child: TextField(
                controller: _digits[index],
                focusNode: _focus[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]'),
                  ),
                  LengthLimitingTextInputFormatter(1),
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final normalized = AuthInput.normalizeDigits(value);
                  if (normalized != value) {
                    _digits[index].value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(
                        offset: normalized.length,
                      ),
                    );
                  }
                  if (normalized.isNotEmpty && index < 3) {
                    _focus[index + 1].requestFocus();
                  } else if (normalized.isEmpty && index > 0) {
                    _focus[index - 1].requestFocus();
                  }
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
