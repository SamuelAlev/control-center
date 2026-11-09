/// A markdown document split into its flat `key: value` frontmatter and body.
///
/// The one parser behind every file-defined harness extension (skills,
/// commands, subagent definitions) — each used to carry its own copy, and the
/// copies disagreed on leading whitespace, key case and quote stripping (one
/// stripped an unmatched trailing quote off `say "hi"`).
///
/// Deliberately not a YAML parser: the fields these files need are flat
/// strings, and a malformed block must degrade to "no frontmatter", not throw.
class MarkdownFrontmatter {
  const MarkdownFrontmatter._({
    required this.fields,
    required this.body,
    required this.hasHeader,
  });

  /// Splits [raw]. Leading whitespace before the opening `---` is ignored; a
  /// fence that is never closed means there is no frontmatter and the whole
  /// document is body.
  factory MarkdownFrontmatter.parse(String raw) {
    final text = raw.trimLeft();
    if (!text.startsWith('---')) {
      return MarkdownFrontmatter._(
        fields: const {},
        body: raw,
        hasHeader: false,
      );
    }
    final close = text.indexOf('\n---', 3);
    final headerStart = text.indexOf('\n', 3);
    if (close < 0 || headerStart < 0 || headerStart > close) {
      return MarkdownFrontmatter._(
        fields: const {},
        body: raw,
        hasHeader: false,
      );
    }
    final fields = <String, String>{};
    for (final line in text.substring(headerStart + 1, close).split('\n')) {
      final idx = line.indexOf(':');
      if (idx <= 0) {
        continue;
      }
      fields[line.substring(0, idx).trim().toLowerCase()] = unquote(
        line.substring(idx + 1).trim(),
      );
    }
    final bodyStart = text.indexOf('\n', close + 1);
    return MarkdownFrontmatter._(
      fields: Map.unmodifiable(fields),
      body: bodyStart < 0 ? '' : text.substring(bodyStart + 1),
      hasHeader: true,
    );
  }

  /// The header's fields: keys lower-cased, values trimmed and unquoted. On a
  /// repeated key the last one wins.
  final Map<String, String> fields;

  /// Everything after the closing fence (the whole document when there is no
  /// frontmatter). Not trimmed.
  final String body;

  /// Whether a complete frontmatter block was found.
  final bool hasHeader;

  /// The value of [key] (case-insensitive), or null when absent.
  String? operator [](String key) => fields[key.toLowerCase()];

  /// Strips ONE matched pair of surrounding single or double quotes.
  static String unquote(String value) {
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}
