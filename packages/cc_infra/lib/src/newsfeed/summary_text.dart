import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Block-level elements whose boundaries separate words in the plain text.
const _blockSelector =
    'p, div, li, ul, ol, br, h1, h2, h3, h4, h5, h6, blockquote, pre, '
    'tr, td, th, section, article, header, footer, figure, figcaption';

final _whitespace = RegExp(r'\s+');
final _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Plain-text summary of a feed item's HTML [html]: one line, whitespace
/// collapsed, with link-only blocks dropped.
///
/// Feeds often follow the real description with a navigation block such as
/// Product Hunt's `<p><a>Discussion</a> | <a>Link</a></p>`. Kept, its
/// indentation and line breaks make the summary's second line blank, so a
/// two-line card ellipsizes an empty line. A block whose only words are link
/// text is dropped, unless nothing else remains.
String summaryTextFromHtml(String html) {
  if (html.trim().isEmpty) {
    return '';
  }
  final Element? body;
  try {
    body = html_parser.parse(html).body;
  } on Object catch (_) {
    return _collapse(html.replaceAll(RegExp('<[^>]+>'), ' '));
  }
  if (body == null) {
    return '';
  }
  final full = _textOf(body);
  for (final block in body.querySelectorAll(_blockSelector).reversed) {
    if (block.parent != null && _isLinkOnly(block)) {
      block.remove();
    }
  }
  final trimmed = _textOf(body);
  return trimmed.isEmpty ? full : trimmed;
}

/// Text of [root] with a space at every block boundary, collapsed.
String _textOf(Element root) {
  final copy = root.clone(true);
  for (final block in copy.querySelectorAll(_blockSelector)) {
    block.append(Text(' '));
  }
  return _collapse(copy.text);
}

/// Whether [block] has links and no words outside them.
bool _isLinkOnly(Element block) {
  if (block.querySelector('a') == null) {
    return false;
  }
  final copy = block.clone(true);
  for (final link in copy.querySelectorAll('a')) {
    link.remove();
  }
  return !_wordChar.hasMatch(copy.text);
}

String _collapse(String text) => text.replaceAll(_whitespace, ' ').trim();
