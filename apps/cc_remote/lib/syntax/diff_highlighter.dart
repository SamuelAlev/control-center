// The phone's entry point to diff syntax highlighting.
//
// The tokenizer (shiki, the CC themes and the curated grammars) is a deferred
// library: nothing is downloaded until the first diff in a language this
// client highlights is opened, and diffs render plain until it arrives. The
// language table is the shared one from cc_syntax, so a path maps to the same
// grammar here as on the desktop.

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_remote/syntax/diff_highlighter_engine.dart'
    deferred as engine;
import 'package:cc_syntax/syntax_languages.dart';

bool _engineLoaded = false;

/// The shiki grammar id for [path], or `null` when the path's language is
/// unknown (the diff stays plain and the tokenizer is never fetched).
String? diffLanguageForPath(String? path) =>
    path == null || path.isEmpty ? null : shikiLangForPath(path);

/// Tokenizes [rows] in [languageId] for the [dark] or light CC theme,
/// returning one token list per row, or `null` to render plain: the grammar
/// is not shipped to the phone, or the tokenizer could not be loaded.
Future<List<List<DiffToken>>?> highlightDiffRows(
  List<DiffLine> rows,
  String languageId, {
  required bool dark,
}) async {
  if (!_engineLoaded) {
    // Concurrent first diffs share one fetch: `loadLibrary` dedupes itself.
    try {
      await engine.loadLibrary();
    } on Object {
      // A failed chunk fetch (offline, mid-deploy) leaves the diff plain;
      // the next opened diff retries.
      return null;
    }
    _engineLoaded = true;
  }
  return engine.highlightDiffRows(rows, languageId, dark: dark);
}
