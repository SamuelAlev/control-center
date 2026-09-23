import 'package:control_center/features/messaging/providers/repo_content_search_provider.dart';
import 'package:flutter/widgets.dart';

/// Characters of the line kept before a match. VS Code's search preview
/// (`MatchImpl.preview` → `lcut(before, 26, '…')`).
const _kLeadingChars = 26;

/// Cap on one preview. VS Code's `MatchImpl.MAX_PREVIEW_CHARS`.
const _kMaxPreviewChars = 250;

/// Prefix VS Code inserts when a preview drops the start of the line.
const _kEllipsis = '…';

/// A content-search line trimmed so the match stays in view, plus the
/// ranges to highlight inside [text].
class SearchLinePreview {
  /// Creates a preview of [text] with [highlights] measured in that string.
  const SearchLinePreview({required this.text, required this.highlights});

  /// The line as shown. May start with `…` when the start was cut.
  final String text;

  /// Half-open ranges of [text] that are matches.
  final List<({int start, int end})> highlights;
}

/// Left-cut [text] to about [n] characters on a word boundary.
///
/// Port of VS Code's `lcut` (`src/vs/base/common/strings.ts`). The result can
/// be longer than [n] so a word is not split. When the cut drops a prefix,
/// [prefix] is prepended. Leading whitespace is always trimmed.
@visibleForTesting
String leftCutAtWordBoundary(String text, int n, {String prefix = ''}) {
  final trimmed = text.trimLeft();
  if (trimmed.length < n) {
    return trimmed;
  }
  var i = 0;
  for (final match in RegExp(r'\b').allMatches(trimmed)) {
    if (trimmed.length - match.start < n) {
      break;
    }
    i = match.start;
  }
  if (i == 0) {
    return trimmed;
  }
  return prefix + trimmed.substring(i).trimLeft();
}

/// The line a search result shows for [line].
///
/// A match near the start is shown from the start (the row clips the tail).
/// A match further in is windowed: roughly [leadingChars] of context stay
/// in front of it and the dropped start is replaced with `…`, matching VS
/// Code's search results. [leadingChars] `0` keeps only the ellipsis.
SearchLinePreview previewSearchLine(
  String line,
  String query, {
  ContentSearchOptions options = const ContentSearchOptions(),
  int leadingChars = _kLeadingChars,
}) {
  final trimmed = line.trimLeft();
  final pattern = _queryPattern(query, options);
  if (trimmed.isEmpty || pattern == null) {
    return SearchLinePreview(text: trimmed, highlights: const []);
  }
  final matches = [
    for (final match in pattern.allMatches(trimmed))
      if (match.end > match.start) match,
  ];
  if (matches.isEmpty) {
    return SearchLinePreview(text: trimmed, highlights: const []);
  }
  final first = matches.first.start;
  final cutBefore = _prefixBeforeMatch(
    trimmed.substring(0, first),
    leadingChars,
  );
  var tail = trimmed.substring(first);
  var limit = _kMaxPreviewChars - cutBefore.length;
  if (limit < 0) {
    limit = 0;
  }
  final firstLen = matches.first.end - matches.first.start;
  if (limit < firstLen) {
    limit = firstLen > _kMaxPreviewChars ? _kMaxPreviewChars : firstLen;
  }
  if (tail.length > limit) {
    tail = tail.substring(0, limit);
  }
  final text = cutBefore + tail;
  final visibleEnd = first + tail.length;
  final shift = cutBefore.length - first;
  final highlights = <({int start, int end})>[];
  for (final match in matches) {
    if (match.start >= visibleEnd) {
      break;
    }
    final start = match.start + shift;
    final end = (match.end > visibleEnd ? visibleEnd : match.end) + shift;
    if (end > start) {
      highlights.add((start: start, end: end));
    }
  }
  return SearchLinePreview(text: text, highlights: highlights);
}

/// Spans for [preview], with each match painted in [highlight].
List<InlineSpan> searchPreviewSpans(
  SearchLinePreview preview,
  TextStyle highlight,
) {
  final text = preview.text;
  if (text.isEmpty) {
    return const [TextSpan(text: '')];
  }
  if (preview.highlights.isEmpty) {
    return [TextSpan(text: text)];
  }
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final range in preview.highlights) {
    final start = range.start.clamp(0, text.length);
    final end = range.end.clamp(start, text.length);
    if (start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, start)));
    }
    if (end > start) {
      spans.add(TextSpan(text: text.substring(start, end), style: highlight));
    }
    cursor = end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans;
}

/// One search-result line. Windows the preview on the match, then shrinks
/// the lead until that match fits the row; text after the match still clips
/// with an end ellipsis.
class SearchMatchPreview extends StatelessWidget {
  /// Creates a preview of [line] for [query].
  const SearchMatchPreview({
    super.key,
    required this.line,
    required this.query,
    required this.style,
    required this.highlight,
    this.options = const ContentSearchOptions(),
  });

  /// The raw matching line (leading whitespace is dropped).
  final String line;

  /// The query that produced [line].
  final String query;

  /// Case, regex and whole-word flags the search ran with.
  final ContentSearchOptions options;

  /// Style of the non-matching text.
  final TextStyle style;

  /// Style painted over each match. Unspecified fields inherit [style].
  final TextStyle highlight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final leading = _leadingThatFits(
          line: line,
          query: query,
          options: options,
          style: style,
          highlight: highlight,
          maxWidth: constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final preview = previewSearchLine(
          line,
          query,
          options: options,
          leadingChars: leading,
        );
        return RichText(
          // RTL carve-out: a grep preview is source text, always LTR.
          textDirection: TextDirection.ltr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: style,
            children: searchPreviewSpans(preview, highlight),
          ),
        );
      },
    );
  }
}

String _prefixBeforeMatch(String before, int leadingChars) {
  final trimmed = before.trimLeft();
  if (trimmed.isEmpty) {
    return '';
  }
  if (leadingChars <= 0) {
    return _kEllipsis;
  }
  final cut = leftCutAtWordBoundary(trimmed, leadingChars, prefix: _kEllipsis);
  final marked = cut.startsWith(_kEllipsis);
  final body = marked ? cut.substring(_kEllipsis.length) : cut;
  // A snapped cut can run past [leadingChars] to keep a whole word — that is
  // the VS Code preview (`…underline plus stronger text`). Only force a tail
  // cut when lcut refused to drop anything, which is a run with no word
  // boundary (`xxxxneedle`) that would otherwise hide the match.
  if (!marked && body.length > leadingChars) {
    return _kEllipsis + body.substring(body.length - leadingChars);
  }
  return cut;
}

RegExp? _queryPattern(String query, ContentSearchOptions options) {
  final q = query.trim();
  if (q.isEmpty) {
    return null;
  }
  final String pattern;
  if (options.regex) {
    pattern = options.wholeWord ? '\\b(?:$q)\\b' : q;
  } else {
    final escaped = RegExp.escape(q);
    pattern = options.wholeWord ? '\\b$escaped\\b' : escaped;
  }
  try {
    return RegExp(pattern, caseSensitive: options.caseSensitive);
  } on FormatException {
    if (!options.regex) {
      return null;
    }
    final escaped = RegExp.escape(q);
    final fallback = options.wholeWord ? '\\b$escaped\\b' : escaped;
    return RegExp(fallback, caseSensitive: options.caseSensitive);
  }
}

int _leadingThatFits({
  required String line,
  required String query,
  required ContentSearchOptions options,
  required TextStyle style,
  required TextStyle highlight,
  required double maxWidth,
  required TextScaler textScaler,
}) {
  if (maxWidth <= 0 || !maxWidth.isFinite) {
    return _kLeadingChars;
  }
  var lo = 0;
  var hi = _kLeadingChars;
  var best = 0;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    final preview = previewSearchLine(
      line,
      query,
      options: options,
      leadingChars: mid,
    );
    if (_fitsThroughFirstMatch(
      preview,
      style,
      highlight,
      maxWidth,
      textScaler,
    )) {
      best = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return best;
}

bool _fitsThroughFirstMatch(
  SearchLinePreview preview,
  TextStyle style,
  TextStyle highlight,
  double maxWidth,
  TextScaler textScaler,
) {
  if (preview.highlights.isEmpty) {
    return true;
  }
  final end = preview.highlights.first.end.clamp(0, preview.text.length);
  final through = SearchLinePreview(
    text: preview.text.substring(0, end),
    highlights: [(start: preview.highlights.first.start, end: end)],
  );
  final matchWidth = _spanWidth(
    TextSpan(style: style, children: searchPreviewSpans(through, highlight)),
    textScaler,
  );
  final fullWidth = _spanWidth(
    TextSpan(style: style, children: searchPreviewSpans(preview, highlight)),
    textScaler,
  );
  if (fullWidth <= maxWidth) {
    return true;
  }
  final ellipsisWidth = _spanWidth(
    TextSpan(text: _kEllipsis, style: style),
    textScaler,
  );
  return matchWidth + ellipsisWidth <= maxWidth;
}

double _spanWidth(InlineSpan span, TextScaler textScaler) {
  final painter = TextPainter(
    text: span,
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
