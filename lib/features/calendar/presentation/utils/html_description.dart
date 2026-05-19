import 'package:html/parser.dart' as html_parser;

/// A calendar event description after HTML has been stripped to readable text,
/// with any hyperlinks pulled out so they can be rendered as tappable rows.
class ParsedDescription {
  /// Creates a [ParsedDescription].
  const ParsedDescription({required this.text, required this.links});

  /// The human-readable text (tags removed, entities decoded, breaks kept).
  final String text;

  /// Hyperlinks found in the description (deduplicated by URL, in order).
  final List<DescriptionLink> links;

  /// Whether there is nothing to show.
  bool get isEmpty => text.isEmpty && links.isEmpty;
}

/// A single hyperlink from a description.
class DescriptionLink {
  /// Creates a [DescriptionLink].
  const DescriptionLink({required this.label, required this.url});

  /// The visible label (falls back to the URL when the anchor had no text).
  final String label;

  /// The destination URL.
  final String url;
}

/// Non-breaking space (what `&nbsp;` decodes to). Treated as ordinary
/// whitespace when collapsing.
final String _nbsp = String.fromCharCode(0xA0);

/// Parses a calendar event [description] — which Google delivers as HTML — into
/// readable text plus its hyperlinks. Falls back to the raw string if it does
/// not look like HTML, so plain-text descriptions are left untouched.
ParsedDescription parseEventDescription(String description) {
  final looksLikeHtml = description.contains('<') && description.contains('>');
  if (!looksLikeHtml) {
    return ParsedDescription(text: description.trim(), links: const []);
  }

  // Turn block/line-break tags into newlines *before* extracting text, since
  // the parser's `.text` concatenates nodes without any layout whitespace.
  final withBreaks = description
      .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(r'</\s*(p|div|li|tr|h[1-6])\s*>', caseSensitive: false),
        '\n',
      );

  final fragment = html_parser.parseFragment(withBreaks);

  final links = <DescriptionLink>[];
  final seen = <String>{};
  for (final anchor in fragment.querySelectorAll('a')) {
    final href = anchor.attributes['href'];
    if (href == null || href.trim().isEmpty || !seen.add(href)) {
      continue;
    }
    final label = anchor.text.trim();
    links.add(DescriptionLink(label: label.isEmpty ? href : label, url: href));
  }

  return ParsedDescription(
    text: _collapseWhitespace(fragment.text ?? ''),
    links: links,
  );
}

/// Collapses horizontal whitespace runs to single spaces and limits blank-line
/// runs to one, so reflowed HTML doesn't render with huge gaps.
String _collapseWhitespace(String raw) {
  final normalized = raw.replaceAll(_nbsp, ' ');
  final out = <String>[];
  var pendingBlank = false;
  for (final line in normalized.split('\n')) {
    final trimmed = line.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
    if (trimmed.isEmpty) {
      pendingBlank = out.isNotEmpty;
      continue;
    }
    if (pendingBlank) {
      out.add('');
      pendingBlank = false;
    }
    out.add(trimmed);
  }
  return out.join('\n').trim();
}
