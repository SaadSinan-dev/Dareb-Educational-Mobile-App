import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tamkeen2/l10n/app_catalog.g.dart';

/// Translates centrally declared product copy; unknown server content is left as-is.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;
  static const supportedLocales = [Locale('ar'), Locale('en')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('ar'));

  static final _templates =
      AppCatalog.englishByArabic.entries
          .where((entry) => entry.key.contains(RegExp(r'\{arg\d+\}')))
          .map(_MessageTemplate.new)
          .toList()
        ..sort((a, b) => b.fixedLength.compareTo(a.fixedLength));

  String translate(String value) {
    final source = AppCatalog.arabicByKey[value] ?? value;
    if (locale.languageCode != 'en') return source;
    final exact = AppCatalog.englishByArabic[source];
    if (exact != null) return exact;
    for (final template in _templates) {
      final match = template.pattern.firstMatch(source);
      if (match == null) continue;
      var result = template.english;
      for (var index = 0; index < template.argumentCount; index++) {
        result = result.replaceAll(
          '{arg$index}',
          translate(match.group(index + 1) ?? ''),
        );
      }
      return result;
    }
    return source;
  }
}

class _MessageTemplate {
  _MessageTemplate(MapEntry<String, String> entry)
    : english = entry.value,
      fixedLength = entry.key.replaceAll(RegExp(r'\{arg\d+\}'), '').length,
      argumentCount = RegExp(r'\{arg\d+\}').allMatches(entry.key).length,
      pattern = _pattern(entry.key);

  final String english;
  final int fixedLength, argumentCount;
  final RegExp pattern;

  static RegExp _pattern(String template) {
    final placeholder = RegExp(r'\{arg\d+\}');
    final pattern = StringBuffer('^');
    var previous = 0;
    for (final match in placeholder.allMatches(template)) {
      pattern.write(RegExp.escape(template.substring(previous, match.start)));
      pattern.write('(.*?)');
      previous = match.end;
    }
    pattern.write(RegExp.escape(template.substring(previous)));
    pattern.write(r'$');
    return RegExp(pattern.toString(), dotAll: true);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ar' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String text) => l10n.translate(text);
}

/// Drop-in for visible text so translated copy stays reactive to locale changes.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
  }) : span = null;

  const AppText.rich(
    this.span, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
  }) : data = null;

  final String? data;
  final InlineSpan? span;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = semanticsLabel == null
        ? null
        : l10n.translate(semanticsLabel!);
    if (span != null) {
      return Text.rich(
        _translateSpan(span!, l10n),
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: label,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );
    }
    return Text(
      l10n.translate(data ?? ''),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: label,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }

  InlineSpan _translateSpan(InlineSpan value, AppLocalizations l10n) {
    if (value is! TextSpan) return value;
    return TextSpan(
      text: value.text == null ? null : l10n.translate(value.text!),
      children: value.children
          ?.map((span) => _translateSpan(span, l10n))
          .toList(),
      style: value.style,
      recognizer: value.recognizer,
      semanticsLabel: value.semanticsLabel == null
          ? null
          : l10n.translate(value.semanticsLabel!),
    );
  }
}
