/// Converts the small CMS HTML fragment to displayable plain text. The result
/// is passed only to text widgets; server markup is never rendered as widgets.
String accountHtmlToText(String source) {
  var value = source;
  for (final tag in ['script', 'style', 'iframe']) {
    value = value.replaceAll(
      RegExp(
        '<\\s*$tag\\b[^>]*>.*?<\\s*/\\s*$tag\\s*>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
  }
  value = value.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
  value = value.replaceAll(
    RegExp(r'<\s*br\b[^>]*>', caseSensitive: false),
    '\n',
  );
  value = value.replaceAll(
    RegExp(r'<\s*/?\s*(?:div|p|h[1-6]|ul|ol|li)\b[^>]*>', caseSensitive: false),
    '\n',
  );
  value = value.replaceAll(RegExp(r'<[^>]*>'), '');
  value = value.replaceAllMapped(
    RegExp(r'&(#(?:x[0-9a-fA-F]+|[0-9]+)|[a-zA-Z]+);'),
    (match) {
      final entity = match.group(1)!;
      if (entity.startsWith('#')) {
        final hex = entity.length > 2 && entity[1].toLowerCase() == 'x';
        final code = int.tryParse(
          entity.substring(hex ? 2 : 1),
          radix: hex ? 16 : 10,
        );
        if (code != null &&
            code > 0 &&
            code <= 0x10ffff &&
            (code < 0xd800 || code > 0xdfff)) {
          return String.fromCharCode(code);
        }
        return match.group(0)!;
      }
      return switch (entity.toLowerCase()) {
        'amp' => '&',
        'lt' => '<',
        'gt' => '>',
        'quot' => '"',
        'apos' || 'nbsp' => entity.toLowerCase() == 'nbsp' ? ' ' : "'",
        _ => match.group(0)!,
      };
    },
  );
  return value
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'[ \t]*\n[ \t]*'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
