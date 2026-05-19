import 'package:html/parser.dart' as html_parser;

/// Slugify.
String slugify(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

/// Safely decodes HTML entities (e.g. `&amp;`, `&#8216;`, `&lt;`) in [input]
/// without executing any markup. Returns the original string on parse errors.
String decodeHtmlEntities(String input) {
  if (input.isEmpty) {
    return input;
  }
  try {
    final fragment = html_parser.parseFragment(input);
    return fragment.text ?? input;
  } on Object catch (_) {
    return input;
  }
}

