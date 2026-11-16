part of 'feed_text_measure.dart';

/// Default top padding above h1–h3, matching `appMarkdownStyle`'s regular
/// (non-compact) register.
const Map<int, double> _defaultHeadingPadding = {1: 14, 2: 12, 3: 10};

/// Default heading sizes relative to the body, matching `appMarkdownStyle`
/// (20 / 18 / 16 over a 14px body).
const Map<int, double> _defaultHeadingScale = {
  1: 20 / 14,
  2: 18 / 14,
  3: 16 / 14,
};

/// Height of a thematic break: a 1px rule with 4px margin either side.
const double _ruleExtent = 9;

/// Blockquote start inset: the 3px border plus the renderer's 12px padding.
const double _blockquoteInset = 15;

/// Blockquote vertical padding (2px top and bottom).
const double _blockquoteVerticalPadding = 4;

/// Code-block body chrome: content padding top and bottom plus the 1px border
/// either side.
final double _codeBlockVerticalChrome = kCodeBlockContentPadding.vertical + 2;

/// Labelled code-block header: header padding, the 32px copy button and the
/// 1px divider under it.
final double _codeBlockHeaderExtent = kCodeBlockHeaderPadding.vertical + 32 + 1;

/// The "Show more" row under a collapsed code block: 1px divider, 2px padding
/// either side, a 32px small button.
const double _codeBlockCollapseRowExtent = 1 + 4 + 32;

/// The "showing first N lines" notice under a truncated oversized block: one
/// 11px caption line plus 10px bottom padding.
const double _codeBlockTruncationNoticeExtent = 10 + 15;

/// Vertical cell padding in a markdown table (6px top and bottom).
const double _tableCellVerticalPadding = 12;

/// Horizontal cell padding in a markdown table (12px either side).
const double _tableCellHorizontalPadding = 24;

final RegExp _fenceOpen = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
final RegExp _heading = RegExp(r'^ {0,3}(#{1,6})(?:[ \t]+(.*?))?[ \t#]*$');
final RegExp _rule = RegExp(r'^ {0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$');
final RegExp _quote = RegExp(r'^ {0,3}> ?(.*)$');
final RegExp _listItem = RegExp(r'^([ \t]*)(?:[-*+]|\d{1,9}[.)])[ \t]+(.*)$');
final RegExp _image = RegExp(r'!\[([^\]]*)\]\([^)]*\)');
final RegExp _link = RegExp(r'\[([^\]]+)\]\([^)]*\)');
final RegExp _autolink = RegExp(r'<((?:https?|mailto):[^>\s]+)>');
final RegExp _inlineMarkers = RegExp(r'\*\*|__|~~|`');
final RegExp _tableSeparatorCell = RegExp(r'^:?-+:?$');

/// Drops the inline markdown syntax that does not render as text, so the
/// laid-out width matches what the reader sees.
String _stripInline(String text) {
  var out = text;
  if (out.contains('](')) {
    out = out
        .replaceAllMapped(_image, (m) => m[1] ?? '')
        .replaceAllMapped(_link, (m) => m[1] ?? '');
  }
  if (out.contains('<')) {
    out = out.replaceAllMapped(_autolink, (m) => m[1] ?? '');
  }
  return out.replaceAll(_inlineMarkers, '');
}

/// The block outline of a markdown source, and how much of it was read.
class _ParseResult {
  const _ParseResult(this.blocks, this.consumedChars);

  final List<_Block> blocks;

  /// Source characters (newlines included) covered by [blocks].
  final int consumedChars;
}

sealed class _Block {
  const _Block();
}

class _Paragraph extends _Block {
  const _Paragraph(this.text);

  final String text;
}

class _Heading extends _Block {
  const _Heading(this.level, this.text);

  final int level;
  final String text;
}

class _Code extends _Block {
  const _Code({
    required this.lineCount,
    required this.chars,
    required this.labeled,
  });

  final int lineCount;
  final int chars;
  final bool labeled;
}

class _Rule extends _Block {
  const _Rule();
}

class _Quote extends _Block {
  const _Quote(this.inner);

  final List<_Block> inner;
}

class _ListItem {
  _ListItem(this.depth, this.text);

  final int depth;
  String text;
}

class _ListBlock extends _Block {
  _ListBlock(this.items);

  final List<_ListItem> items;
  bool tight = true;
}

class _Table extends _Block {
  const _Table(this.rows);

  final List<List<String>> rows;
}
