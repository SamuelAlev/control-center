import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_natives/cc_natives.dart';

/// Resolves the tree-sitter runtime + grammar for one language, or null.
///
/// A function rather than a `GrammarManager`, so this stays free of the Dio
/// and data-dir plumbing the manager needs to DOWNLOAD a grammar. Nothing here
/// installs anything; it only asks where the staged libraries are.
typedef GrammarPathResolver = Future<GrammarPaths?> Function(String languageId);

/// Holds the one tree-sitter parser the structural tools share.
///
/// **Why one, held here, rather than one per tool call.** A `TreeSitterParser`
/// owns native handles — a parser per language, a compiled-query cache — and
/// those are allocations an isolate's death does NOT reclaim. One per
/// `ast_grep` call would leak a parser per call unless every path out of the
/// tool disposed it, and would throw away the per-language setup that makes the
/// second file cheaper than the first.
///
/// **Why warming is explicit and not lazy-on-first-use.** Resolving grammars
/// touches the filesystem, and the tool registry is built synchronously per
/// run — a lazy resolve would mean the FIRST run of a fresh server silently has
/// no structural tools while every later one does, which is the kind of
/// difference nobody reproduces. So the server warms it once, after the ready
/// banner: the desktop parses that banner under a hard 20s timeout and kills
/// the child on expiry, so nothing that touches disk belongs before it.
class AstParserProvider {
  /// Creates an [AstParserProvider] over [resolve].
  AstParserProvider({required GrammarPathResolver resolve}) : _resolve = resolve;

  final GrammarPathResolver _resolve;
  TreeSitterParser? _parser;
  var _warmed = false;

  /// The shared parser, or null when the tree-sitter grammars are not staged.
  ///
  /// Null rather than an exception: the caller's answer to "no parser" is to
  /// not register the structural tools at all, which beats advertising a tool
  /// whose every call is an error.
  TreeSitterParser? get parserIfReady => _parser;

  /// Whether [warm] has run.
  bool get isWarmed => _warmed;

  /// Resolves every staged grammar and builds the parser. Idempotent.
  Future<void> warm() async {
    if (_warmed) {
      return;
    }
    _warmed = true;
    String? runtimePath;
    final grammarPaths = <String, String>{};
    // Every language the walker recognises, because a structural search is
    // asked for by language and a grammar that is staged but unlisted would be
    // invisible.
    for (final languageId in kLanguageByExtension.values.toSet()) {
      try {
        final paths = await _resolve(languageId);
        if (paths == null) {
          continue;
        }
        runtimePath ??= paths.runtimePath;
        grammarPaths[languageId] = paths.grammarPath;
      } on Object catch (e) {
        // A grammar that will not resolve costs its own language, never the
        // rest of the set.
        CcInfraLog.warning('grammar lookup failed for $languageId: $e');
      }
    }
    if (runtimePath == null || grammarPaths.isEmpty) {
      CcInfraLog.info(
        'tree-sitter grammars are not staged — structural search is off',
      );
      return;
    }
    _parser = TreeSitterParser(
      TreeSitterLoader(runtimePath: runtimePath, grammarPaths: grammarPaths),
    );
    CcInfraLog.info(
      'structural search ready (${grammarPaths.length} grammars)',
    );
  }

  /// Frees the native handles. Call on server shutdown.
  void dispose() {
    _parser?.dispose();
    _parser = null;
    _warmed = false;
  }
}
