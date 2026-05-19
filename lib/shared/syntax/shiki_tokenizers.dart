// The app-side tokenize seam over shiki_flutter: one shared highlighter,
// CC themes always registered, grammars resolved through the platform
// registry, every failure mode collapsed to `null` ("render plain") so a
// missing grammar or a grammar bug can never take down a build.
//
// The PR-diff worker does NOT use this seam — it owns a per-isolate
// highlighter in diff_worker_core.dart (same engine, same theme constants).
//
// FLUTTER-FREE ON PURPOSE: consumed by both widget code (which converts
// ThemedTokens to TextSpans) and pure-Dart code.

import 'dart:async';

import 'package:control_center/shared/syntax/cc_shiki_theme.dart';
import 'package:control_center/shared/syntax/grammar_registry.dart';
import 'package:control_center/shared/syntax/token_lines.dart';
import 'package:shiki_flutter/engine.dart';

export 'package:control_center/shared/syntax/token_lines.dart'
    show reattachCarriageReturns;

/// Test hook: forces [CcShikiTokenizer.tokenizeAsync] to run synchronously so
/// widget tests can assert colored output without pumping real isolates.
/// Mirrors `DiffWorkerPool.debugForceInline`.
bool debugDisableShikiAsync = false;

/// Longest line shiki will tokenize before emitting the whole line as one
/// plain token — a guard against minified single-line bundles that
/// backtracking grammars choke on. highlight.js had no such guard.
const int kShikiMaxTokenizedLineLength = 4000;

/// The shared main-isolate tokenizer.
class CcShikiTokenizer {
  CcShikiTokenizer._()
    : _highlighter = ShikiHighlighter(
        // Shiki's own token LRU backs peek/async; keep it small — the
        // span-level LRU in code_highlighter.dart is the cache that
        // matters and paying 4MiB (shiki's default) on top of it double-
        // stores every block.
        cache: TokenCache(maxEntries: 32, maxChars: 1024 * 1024),
      );

  /// The process-wide instance.
  static final CcShikiTokenizer instance = CcShikiTokenizer._();

  final ShikiHighlighter _highlighter;
  bool _themesReady = false;
  final Set<String> _ensuredLangs = <String>{};

  TokenizeOptions _options(String langId, {required bool dark}) =>
      TokenizeOptions(
        lang: langId,
        theme: ccThemeId(dark: dark),
        tokenizeMaxLineLength: kShikiMaxTokenizedLineLength,
      );

  void _ensureThemes() {
    if (_themesReady) {
      return;
    }
    ensureCcThemes(_highlighter);
    _themesReady = true;
  }

  /// Loads [langId]'s grammar into the highlighter if the platform registry
  /// has it resident. Returns false when it isn't available synchronously
  /// (unknown id, or a not-yet-fetched web pack).
  bool _ensureLang(String langId) {
    if (_ensuredLangs.contains(langId)) {
      return true;
    }
    final lang = codeLanguageForId(langId);
    if (lang == null) {
      // Web: kick the deferred pack fetch so a later rebuild can succeed.
      unawaited(ensureLanguageAvailable(langId));
      return false;
    }
    _highlighter.ensureLanguage(lang);
    _ensuredLangs.add(langId);
    return true;
  }

  /// Tokenizes synchronously. Returns `null` when [langId] is null/unknown/
  /// not resident or tokenization fails — callers render plain text.
  ///
  /// Output preserves the source exactly: shiki normalizes `\r\n` to `\n`,
  /// so stripped carriage returns are re-attached before returning (span
  /// concatenation must reproduce the input byte-for-byte — the intraline
  /// emphasis and diff offset math depend on it).
  List<List<ThemedToken>>? tokenizeSync(
    String code, {
    required String? langId,
    required bool dark,
  }) {
    if (langId == null || code.isEmpty) {
      return null;
    }
    _ensureThemes();
    if (!_ensureLang(langId)) {
      return null;
    }
    try {
      final lines = _highlighter.codeToTokens(
        code,
        _options(langId, dark: dark),
      );
      return reattachCarriageReturns(code, lines);
    } on Object {
      return null;
    }
  }

  /// Tokenizes off the UI thread (background isolate on native, Web Worker on
  /// web when installed). Same `null` = plain contract as [tokenizeSync].
  Future<List<List<ThemedToken>>?> tokenizeAsync(
    String code, {
    required String? langId,
    required bool dark,
  }) async {
    if (langId == null || code.isEmpty) {
      return null;
    }
    _ensureThemes();
    if (!_ensureLang(langId)) {
      final available = await ensureLanguageAvailable(langId);
      if (!available || !_ensureLang(langId)) {
        return null;
      }
    }
    if (debugDisableShikiAsync) {
      return tokenizeSync(code, langId: langId, dark: dark);
    }
    try {
      final lines = await _highlighter.codeToTokensAsync(
        code,
        _options(langId, dark: dark),
      );
      return reattachCarriageReturns(code, lines);
    } on Object {
      return null;
    }
  }

  /// Already-computed tokens for these inputs, synchronously, or `null`.
  /// Lets async surfaces render colored on the first frame after the tokens
  /// exist (no placeholder flash on rebuild).
  List<List<ThemedToken>>? peek(
    String code, {
    required String? langId,
    required bool dark,
  }) {
    if (langId == null || code.isEmpty) {
      return null;
    }
    _ensureThemes();
    if (!_ensuredLangs.contains(langId)) {
      return null;
    }
    try {
      final lines = _highlighter.peekTokens(code, _options(langId, dark: dark));
      return lines == null ? null : reattachCarriageReturns(code, lines);
    } on Object {
      return null;
    }
  }

  /// Pre-warms [langIds] (resident grammars only) and both CC themes.
  void warmUp(Iterable<String> langIds) {
    _ensureThemes();
    for (final id in langIds) {
      _ensureLang(id);
    }
  }
}
