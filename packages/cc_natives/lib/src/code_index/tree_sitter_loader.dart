import 'dart:ffi';

import 'package:cc_natives/src/native_library.dart';

/// Loads the `libtree-sitter` runtime and per-language grammar libraries via
/// `DynamicLibrary`, degrading gracefully when the natives aren't installed.
///
/// Mirrors `FffFileSearch`'s loader: try a list of candidate paths, swallow
/// `ArgumentError` (library absent) and any other load failure, and report
/// availability via [isAvailable]. Callers must no-op when unavailable.
///
/// Construct with explicit paths (resolved by `GrammarManager`) so it can also
/// run inside an isolate — FFI handles can't cross isolate boundaries, but the
/// String paths can, and each isolate builds its own loader.
class TreeSitterLoader {
/// Creates a [TreeSitterLoader] with explicit paths.
  TreeSitterLoader({this.runtimePath, Map<String, String>? grammarPaths})
    : _grammarPaths = grammarPaths ?? const {};

  /// Explicit path to `libtree-sitter`, if known. Falls back to platform
  /// candidate names (bundled beside the app or on the loader path).
  final String? runtimePath;

  /// Explicit `languageId` → grammar-lib path overrides.
  final Map<String, String> _grammarPaths;

  DynamicLibrary? _runtime;
  bool _runtimeAttempted = false;
  final Map<String, DynamicLibrary?> _grammars = {};

  /// The loaded runtime library, or null when unavailable.
  DynamicLibrary? get runtimeLib {
    if (!_runtimeAttempted) {
      _runtimeAttempted = true;
      _runtime = tryOpenFirst([
        ?runtimePath,
        ...bundledLibraryCandidates('tree-sitter'),
      ]);
    }
    return _runtime;
  }

  /// The grammar library exporting `tree_sitter_<languageId>`. Falls back to
  /// the runtime lib (grammars are sometimes statically linked into it).
  DynamicLibrary? grammarLib(String languageId) {
    if (_grammars.containsKey(languageId)) {
      return _grammars[languageId];
    }
    final lib =
        tryOpenFirst([
          if (_grammarPaths[languageId] != null) _grammarPaths[languageId]!,
          ...bundledLibraryCandidates('tree-sitter-$languageId'),
        ]) ??
        runtimeLib;
    _grammars[languageId] = lib;
    return lib;
  }

  /// True when the runtime library loaded successfully.
  bool get isAvailable => runtimeLib != null;

}
