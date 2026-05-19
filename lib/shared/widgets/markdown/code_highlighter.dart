import 'dart:collection';

import 'package:control_center/shared/syntax/cc_shiki_theme.dart';
import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:flutter/painting.dart';
import 'package:shiki_flutter/engine.dart' show ThemedToken;

/// Shared span-level highlighter over the shiki tokenizer
/// ([CcShikiTokenizer]): converts [ThemedToken]s to flat, leaf-only
/// [TextSpan]s (non-null `.text`, never mutated — the
/// `applyIntralineBackground` contract) and caches results in process-global
/// LRUs so re-rendering the same block — scroll-in, streaming rebuilds,
/// theme-stable repaints — never re-tokenizes.
///
/// Language ids are canonical shiki ids resolved via
/// `shared/syntax/syntax_languages.dart` (`shikiLangForFence` /
/// `shikiLangForPath`). Colors come from the CC theme
/// (`shared/syntax/cc_shiki_theme.dart`); unmatched tokens carry no color and
/// inherit the caller's base style.

/// Cache key for a highlighted block: language, theme identity (id +
/// revision), and the raw code string.
typedef _HighlightKey = (String languageId, String themeId, String code);

/// Maximum number of entries per highlight cache.
const int _maxCacheEntries = 128;

/// Maximum total source characters per highlight cache (~2MB).
const int _maxCacheChars = 2 * 1024 * 1024;

/// Items larger than this are never cached (they would evict everything else).
const int _maxCacheableItemChars = 100 * 1024;

/// A small LRU over highlighted results, bounded both by entry count and by
/// total source characters (the spans roughly scale with the source size).
class _HighlightLru<V> {
  final LinkedHashMap<_HighlightKey, V> _map =
      LinkedHashMap<_HighlightKey, V>();
  int _chars = 0;

  V? get(_HighlightKey key) {
    final hit = _map.remove(key);
    if (hit == null) {
      return null;
    }
    // Reinsert to refresh LRU order.
    _map[key] = hit;
    return hit;
  }

  void put(_HighlightKey key, V value) {
    if (_map.remove(key) != null) {
      _chars -= key.$3.length;
    }
    _map[key] = value;
    _chars += key.$3.length;
    while (_map.length > _maxCacheEntries || _chars > _maxCacheChars) {
      final oldest = _map.keys.first;
      _map.remove(oldest);
      _chars -= oldest.$3.length;
    }
  }

  void clear() {
    _map.clear();
    _chars = 0;
  }
}

/// Process-global cache of whole-block highlight results, keyed by
/// (languageId, themeId, code). Shared across every code surface (markdown
/// fences, tool bodies, previews).
final _HighlightLru<List<InlineSpan>> _spanCache = _HighlightLru();

/// Sibling cache for the per-line form (see [highlightCodeLines]), keyed
/// identically.
final _HighlightLru<List<List<InlineSpan>>> _lineCache = _HighlightLru();

/// Number of times a real tokenize (a cache miss) has run. Exposed for tests
/// to prove caching works; mirrors `CachedMarkdown.debugParseCount`.
int debugHighlightParseCount = 0;

/// Clears the process-global highlight caches (both the span cache and the
/// per-line cache). Called on theme-revision changes and (on web) after a
/// deferred grammar pack loads; also useful in tests.
void clearHighlightCache() {
  _spanCache.clear();
  _lineCache.clear();
}

/// Whether a surface may tokenize [lineCount] lines of [languageId]
/// synchronously inside `build()` without risking a dropped frame. Callers
/// above the budget should render plain and swap colors in via
/// [highlightCodeLinesAsync] (rebuilds hit the LRU through
/// [peekHighlightedLines]).
bool shouldHighlightSynchronously({
  required String? languageId,
  required int lineCount,
}) =>
    languageId == null ||
    lineCount <= syncLineBudget(syntaxWeightFor(languageId));

/// Tokenizes [code] with shiki for [languageId] and returns coloured
/// [TextSpan]s for [dark]. Each span carries only a `color` override; the
/// caller supplies the shared base style (mono font, size, weight) on the
/// wrapping [TextSpan] / `Text.rich`.
///
/// Results are cached in a process-global LRU keyed by
/// (languageId, theme identity, code) — bounded to [_maxCacheEntries]
/// entries / [_maxCacheChars] total source chars, with items over
/// [_maxCacheableItemChars] never cached. Pass `cache: false` for volatile
/// content (e.g. a still-streaming code block) whose string changes on every
/// build and would only churn the cache.
///
/// Falls back to a single uncoloured span when there's no language, the code
/// is empty, the grammar isn't available, or tokenization fails — an unknown
/// fence degrades to plain monospace text rather than failing.
List<InlineSpan> highlightCodeSpans({
  required String code,
  required String? languageId,
  required bool dark,
  bool cache = true,
}) {
  if (languageId == null || code.isEmpty) {
    return [TextSpan(text: code)];
  }

  final cacheable = cache && code.length <= _maxCacheableItemChars;
  final key = (languageId, ccThemeCacheId(dark: dark), code);
  if (cacheable) {
    final hit = _spanCache.get(key);
    if (hit != null) {
      return hit;
    }
  }

  final lines = _tokenize(code: code, languageId: languageId, dark: dark);
  if (lines == null) {
    return [TextSpan(text: code)];
  }
  final spans = _joinLineSpans(_toLineSpans(lines));
  if (cacheable) {
    _spanCache.put(key, spans);
  }
  return spans;
}

/// Highlights [code] as ONE whole-block tokenize and returns per-line span
/// lists (shiki's output is per-line natively, with grammar state carried
/// across lines — multi-line constructs stay correct).
///
/// This is the per-line rendering path (line-number gutters, diff rows). A
/// blank line yields an empty inner list. The result is cached in a sibling
/// LRU keyed identically to [highlightCodeSpans].
List<List<InlineSpan>> highlightCodeLines({
  required String code,
  required String? languageId,
  required bool dark,
}) {
  if (languageId == null || code.isEmpty) {
    return _plainLines(code);
  }
  final cacheable = code.length <= _maxCacheableItemChars;
  final key = (languageId, ccThemeCacheId(dark: dark), code);
  if (cacheable) {
    final hit = _lineCache.get(key);
    if (hit != null) {
      return hit;
    }
  }

  final tokenLines =
      _tokenize(code: code, languageId: languageId, dark: dark);
  if (tokenLines == null) {
    return _plainLines(code);
  }
  final lines = _toLineSpans(tokenLines);
  if (cacheable) {
    _lineCache.put(key, lines);
  }
  return lines;
}

/// Already-highlighted per-line spans for these inputs, or `null` when a real
/// tokenize would be needed. Lets async surfaces render coloured output
/// immediately on rebuild once [highlightCodeLinesAsync] has completed.
List<List<InlineSpan>>? peekHighlightedLines({
  required String code,
  required String? languageId,
  required bool dark,
}) {
  if (languageId == null || code.isEmpty) {
    return _plainLines(code);
  }
  if (code.length > _maxCacheableItemChars) {
    return null;
  }
  return _lineCache.get((languageId, ccThemeCacheId(dark: dark), code));
}

/// Whole-block sibling of [peekHighlightedLines]: already-highlighted flat
/// spans, or `null` when a real tokenize would be needed.
List<InlineSpan>? peekHighlightedSpans({
  required String code,
  required String? languageId,
  required bool dark,
}) {
  if (languageId == null || code.isEmpty) {
    return [TextSpan(text: code)];
  }
  if (code.length > _maxCacheableItemChars) {
    return null;
  }
  return _spanCache.get((languageId, ccThemeCacheId(dark: dark), code));
}

/// Whole-block sibling of [highlightCodeLinesAsync]: tokenizes off the UI
/// thread and fills the span LRU. Returns a single plain span when the
/// language is unavailable or tokenization fails.
Future<List<InlineSpan>> highlightCodeSpansAsync({
  required String code,
  required String? languageId,
  required bool dark,
}) async {
  if (languageId == null || code.isEmpty) {
    return [TextSpan(text: code)];
  }
  final key = (languageId, ccThemeCacheId(dark: dark), code);
  final cacheable = code.length <= _maxCacheableItemChars;
  if (cacheable) {
    final hit = _spanCache.get(key);
    if (hit != null) {
      return hit;
    }
  }
  debugHighlightParseCount++;
  final tokenLines = await CcShikiTokenizer.instance
      .tokenizeAsync(code, langId: languageId, dark: dark);
  if (tokenLines == null) {
    return [TextSpan(text: code)];
  }
  final spans = _joinLineSpans(_toLineSpans(tokenLines));
  if (cacheable) {
    _spanCache.put(key, spans);
  }
  return spans;
}

/// Tokenizes off the UI thread and fills the per-line LRU, so a later
/// rebuild's [peekHighlightedLines] (or [highlightCodeLines]) is a cache hit.
/// Returns plain per-line spans when the language is unavailable or
/// tokenization fails.
Future<List<List<InlineSpan>>> highlightCodeLinesAsync({
  required String code,
  required String? languageId,
  required bool dark,
}) async {
  if (languageId == null || code.isEmpty) {
    return _plainLines(code);
  }
  final key = (languageId, ccThemeCacheId(dark: dark), code);
  final cacheable = code.length <= _maxCacheableItemChars;
  if (cacheable) {
    final hit = _lineCache.get(key);
    if (hit != null) {
      return hit;
    }
  }
  debugHighlightParseCount++;
  final tokenLines = await CcShikiTokenizer.instance
      .tokenizeAsync(code, langId: languageId, dark: dark);
  if (tokenLines == null) {
    return _plainLines(code);
  }
  final lines = _toLineSpans(tokenLines);
  if (cacheable) {
    _lineCache.put(key, lines);
  }
  return lines;
}

/// The real tokenize (cache-miss path). Bumps [debugHighlightParseCount].
/// Returns `null` when the caller should render plain.
List<List<ThemedToken>>? _tokenize({
  required String code,
  required String languageId,
  required bool dark,
}) {
  debugHighlightParseCount++;
  return CcShikiTokenizer.instance
      .tokenizeSync(code, langId: languageId, dark: dark);
}

/// Converts shiki token lines to flat, leaf-only [TextSpan] lines. Spans
/// carry only a color (or no style at all for base-styled tokens); empty
/// tokens are dropped; a blank line stays an empty list.
List<List<InlineSpan>> _toLineSpans(List<List<ThemedToken>> tokenLines) {
  return [
    for (final line in tokenLines)
      [
        for (final token in line)
          if (token.content.isNotEmpty)
            TextSpan(
              text: token.content,
              style: switch (ccArgbForTokenColor(token.color)) {
                null => null,
                final argb => TextStyle(color: Color(argb)),
              },
            ),
      ],
  ];
}

/// Joins per-line spans into one flat whole-block list with `'\n'` separator
/// spans, preserving the round-trip invariant (concatenated text == source).
List<InlineSpan> _joinLineSpans(List<List<InlineSpan>> lines) {
  final spans = <InlineSpan>[];
  for (var i = 0; i < lines.length; i++) {
    if (i > 0) {
      spans.add(const TextSpan(text: '\n'));
    }
    spans.addAll(lines[i]);
  }
  if (spans.isEmpty) {
    return const [TextSpan(text: '')];
  }
  return spans;
}

/// Plain (uncoloured) per-line spans: one span per non-empty line, an empty
/// list for a blank line.
List<List<InlineSpan>> _plainLines(String code) {
  return [
    for (final line in code.split('\n'))
      if (line.isEmpty) const <InlineSpan>[] else [TextSpan(text: line)],
  ];
}
