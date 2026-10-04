import 'dart:convert';
import 'dart:io';

/// Generates typed source-copy constants and the runtime catalog from ARB files.
/// Run `dart run tool/generate_localizations.dart` after editing translations.
void main(List<String> args) {
  const directory = 'lib/l10n';
  final folder = Directory(directory)..createSync(recursive: true);
  if (args.contains('--bootstrap')) {
    final entries = <Map<String, dynamic>>[];
    for (final part in [1, 2]) {
      final source = File('build/localization-translated-$part.json');
      final value = jsonDecode(source.readAsStringSync()) as List<dynamic>;
      entries.addAll(value.cast<Map<String, dynamic>>());
    }
    final ar = <String, String>{'@@locale': 'ar'};
    final en = <String, String>{'@@locale': 'en'};
    for (final entry in entries) {
      final key = entry['key'] as String;
      if (ar.containsKey(key)) throw FormatException('Duplicate key: $key');
      ar[key] = entry['ar'] as String;
      en[key] = entry['en'] as String;
    }
    File(
      '${folder.path}/app_ar.arb',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(ar));
    File(
      '${folder.path}/app_en.arb',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(en));
  }

  final ar =
      (jsonDecode(File('$directory/app_ar.arb').readAsStringSync())
              as Map<String, dynamic>)
          .cast<String, String>();
  final en =
      (jsonDecode(File('$directory/app_en.arb').readAsStringSync())
              as Map<String, dynamic>)
          .cast<String, String>();
  ar.remove('@@locale');
  en.remove('@@locale');
  if (ar.keys.toSet().difference(en.keys.toSet()).isNotEmpty ||
      en.keys.toSet().difference(ar.keys.toSet()).isNotEmpty) {
    throw const FormatException('Translation keys differ');
  }
  for (final key in ar.keys) {
    final placeholders = RegExp(r'\{arg\d+\}');
    final arArgs = placeholders
        .allMatches(ar[key]!)
        .map((m) => m.group(0))
        .toSet();
    final enArgs = placeholders
        .allMatches(en[key]!)
        .map((m) => m.group(0))
        .toSet();
    if (arArgs.length != enArgs.length || !arArgs.containsAll(enArgs)) {
      throw FormatException('Placeholder mismatch: $key');
    }
  }

  String literal(String value) => jsonEncode(value).replaceAll(r'$', r'\$');
  final constants = StringBuffer(
    '// Generated from app_ar.arb. Edit the ARB, then run the generator.\n'
    'abstract final class AppCopy {\n',
  );
  for (final entry in ar.entries) {
    constants.writeln('  static const ${entry.key} = ${literal(entry.value)};');
  }
  constants.writeln('''
  static String format(String template, List<Object?> args) {
    var result = template;
    for (var index = 0; index < args.length; index++) {
      result = result.replaceAll('{arg\$index}', '\${args[index] ?? ''}');
    }
    return result;
  }
''');
  constants.writeln('}');
  File('$directory/app_copy.g.dart').writeAsStringSync(constants.toString());

  final catalog = StringBuffer(
    '// Generated from app_ar.arb and app_en.arb. Do not edit.\n'
    'abstract final class AppCatalog {\n'
    '  static const arabicByKey = <String, String>{\n',
  );
  for (final key in ar.keys) {
    catalog.writeln('    ${literal(key)}: ${literal(ar[key]!)},');
  }
  catalog.write(
    '  };\n'
    '  static const englishByArabic = <String, String>{\n',
  );
  for (final key in ar.keys) {
    catalog.writeln('    ${literal(ar[key]!)}: ${literal(en[key]!)},');
  }
  catalog.writeln('  };\n}');
  File('$directory/app_catalog.g.dart').writeAsStringSync(catalog.toString());
  stdout.writeln('Generated ${ar.length} localized messages.');
}
