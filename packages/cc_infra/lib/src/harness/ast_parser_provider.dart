import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_natives/cc_natives.dart';

/// Resolves the tree-sitter runtime + grammar for one language, or null.
///
/// A function rather than a `GrammarManager`, so this stays free of the Dio
/// and data-dir plumbing the manager needs to DOWNLOAD a grammar. Nothing here
/// installs anything; it only asks where the staged libraries are.
typedef GrammarPathResolver = Future<GrammarPaths?> Function(String languageId);

/// Shared tree-sitter parser for structural tools.
///
/// One instance: native handles leak if created per call; query cache makes
/// later files cheaper. Warm explicitly after the ready banner (lazy resolve
/// would leave the first run without structural tools; disk I/O must not run
/// before the desktop's 20s ready timeout).
class AstParserProvider {
  /// Creates an [AstParserProvider] over [_resolve].
  AstParserProvider({required this._resolve});

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
