// The phone's diff tokenizer: shiki with the CC themes over the curated
// grammar tier, one grammar run per hunk.
//
// LOADED DEFERRED, ONLY through diff_highlighter.dart. The engine, the theme
// JSON and the ~50 curated grammars are megabytes of compiled code; importing
// this library eagerly from anywhere else in cc_remote puts all of it on the
// PWA's cold load instead of on the first opened diff.

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_syntax/cc_shiki_theme.dart';
import 'package:cc_syntax/curated_grammars.dart';
import 'package:cc_syntax/token_lines.dart';
import 'package:shiki_flutter/engine.dart';

/// Test hook: tokenize on the calling isolate instead of shiki's worker, so
/// widget tests see colored rows without pumping a real isolate.
bool debugTokenizeInline = false;

/// Guard against minified single-line bundles that backtracking grammars
/// choke on; such a line comes back as one plain token. Same value as the
/// desktop's `kShikiMaxTokenizedLineLength`.
const int _kMaxTokenizedLineLength = 4000;

/// One highlighter for the page. On web, `codeToTokensAsync` runs in
/// shiki's tokenize Web Worker (`web/shiki_tokenize_worker.js`) and falls
/// back to the main thread when that script is unavailable.
final ShikiHighlighter _highlighter = ShikiHighlighter(
  // The diff view keeps its own tokens per patch; this cache only has to
  // absorb a rebuild that re-requests the same hunk.
  cache: TokenCache(maxEntries: 32, maxChars: 512 * 1024),
);
bool _themesReady = false;
final Set<String> _loadedLanguages = <String>{};

/// Tokenizes [rows] (a prefix of a parsed patch) and returns one token list
/// per row, aligned with [rows], or `null` when [languageId] is not shipped.
///
/// Hunk headers and gap markers come back as a single plain token; each run
/// of context/added/removed rows between them is ONE shiki call, so grammar
/// state carries across lines exactly as in the desktop diff worker. A hunk
/// that fails to tokenize, or a row that does not round-trip to its source,
/// degrades to plain rather than painting the wrong characters.
Future<List<List<DiffToken>>?> highlightDiffRows(
  List<DiffLine> rows,
  String languageId, {
  required bool dark,
}) async {
  final grammar = curatedGrammars[languageId];
  if (grammar == null) {
    return null;
  }
  if (!_themesReady) {
    ensureCcThemes(_highlighter);
    _themesReady = true;
  }
  if (_loadedLanguages.add(languageId)) {
    _highlighter.ensureLanguage(grammar);
  }

  final result = <List<DiffToken>>[];
  var i = 0;
  while (i < rows.length) {
    if (_isBand(rows[i])) {
      result.add([DiffToken(rows[i].content, null)]);
      i++;
      continue;
    }
    final start = i;
    while (i < rows.length && !_isBand(rows[i])) {
      i++;
    }
    result.addAll(
      await _tokenizeHunk(rows.sublist(start, i), languageId, dark: dark),
    );
  }
  return result;
}

bool _isBand(DiffLine line) =>
    line.kind == DiffLineKind.hunkHeader || line.kind == DiffLineKind.expandGap;

Future<List<List<DiffToken>>> _tokenizeHunk(
  List<DiffLine> rows,
  String languageId, {
  required bool dark,
}) async {
  List<List<DiffToken>> plain() => [
    for (final row in rows) [DiffToken(row.content, null)],
  ];
  final text = rows.map((r) => r.content).join('\n');
  if (text.isEmpty) {
    return plain();
  }
  final options = TokenizeOptions(
    lang: languageId,
    theme: ccThemeId(dark: dark),
    tokenizeMaxLineLength: _kMaxTokenizedLineLength,
  );
  List<List<ThemedToken>> lines;
  try {
    lines = debugTokenizeInline
        ? _highlighter.codeToTokens(text, options)
        : await _highlighter.codeToTokensAsync(text, options);
    lines = reattachCarriageReturns(text, lines);
  } on Object {
    return plain();
  }
  if (lines.length != rows.length) {
    // The gutter numbers come from the parser; if the tokenizer sees a
    // different line count, trust the parser.
    return plain();
  }
  return [
    for (var r = 0; r < rows.length; r++) _rowTokens(lines[r], rows[r].content),
  ];
}

/// One row's tokens, or the row as a single plain token when the tokens do
/// not concatenate back to [content].
List<DiffToken> _rowTokens(List<ThemedToken> line, String content) {
  final tokens = <DiffToken>[];
  var chars = 0;
  for (final t in line) {
    if (t.content.isEmpty) {
      continue;
    }
    tokens.add(DiffToken(t.content, ccArgbForTokenColor(t.color)));
    chars += t.content.length;
  }
  if (tokens.isEmpty || chars != content.length) {
    return [DiffToken(content, null)];
  }
  return tokens;
}
