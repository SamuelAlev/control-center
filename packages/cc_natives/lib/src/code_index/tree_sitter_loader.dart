import 'dart:ffi';

import 'package:cc_natives/src/native_library.dart';

/// Loads the `libtree-sitter` runtime and per-language grammar libraries via
/// `DynamicLibrary`.
///
/// Mirrors `FffFileSearch`'s loader: try a list of candidate paths, swallow
/// `ArgumentError` (library absent) and any other load failure and report
/// availability via [isAvailable]. A null result here is a PROBE RESULT, not a
/// licence to degrade — the natives are required and `TreeSitterParser` turns
/// a miss into a thrown `TreeSitterUnavailable`. `cc_server` additionally
/// refuses to boot when its preflight cannot resolve the runtime or any of the
/// shipped grammars.
///
/// Construct with explicit paths (resolved by `GrammarManager`) so it can also
/// run inside an isolate — FFI handles can't cross isolate boundaries, but the
/// String paths can and each isolate builds its own loader.
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

  /// The grammar library exporting `tree_sitter_<languageId>`, or null when the
  /// grammar dylib is not installed.
  ///
  /// Deliberately does NOT fall back to [runtimeLib]: this repo's builds always
  /// ship each grammar as its own `libtree-sitter-<languageId>` (see
  /// `scripts/natives/build_tree_sitter.sh`), so handing back the runtime would
  /// only turn "grammar missing" into a confusing `tree_sitter_<id>`
  /// symbol-lookup failure deeper in `TreeSitterParser` instead of the
  /// actionable `TreeSitterUnavailable`.
  DynamicLibrary? grammarLib(String languageId) {
    if (_grammars.containsKey(languageId)) {
      return _grammars[languageId];
    }
    final lib = tryOpenFirst([
      ?_grammarPaths[languageId],
      ...bundledLibraryCandidates('tree-sitter-$languageId'),
    ]);
    _grammars[languageId] = lib;
    return lib;
  }

  /// True when the runtime library loaded successfully.
  bool get isAvailable => runtimeLib != null;
}
