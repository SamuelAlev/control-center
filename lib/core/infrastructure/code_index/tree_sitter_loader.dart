import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

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
      _runtime = _tryOpen([
        ?runtimePath,
        ..._runtimeCandidates(),
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
        _tryOpen([
          if (_grammarPaths[languageId] != null) _grammarPaths[languageId]!,
          ..._grammarCandidates(languageId),
        ]) ??
        runtimeLib;
    _grammars[languageId] = lib;
    return lib;
  }

  /// True when the runtime library loaded successfully.
  bool get isAvailable => runtimeLib != null;

  List<String> _runtimeCandidates() {
    if (Platform.isMacOS) {
      return const [
        'libtree-sitter.dylib',
        '@executable_path/../Frameworks/libtree-sitter.dylib',
      ];
    }
    if (Platform.isLinux) {
      return linuxCandidates(
        'libtree-sitter.so',
        File(Platform.resolvedExecutable).parent.path,
      );
    }
    if (Platform.isWindows) {
      return const ['tree-sitter.dll', 'libtree-sitter.dll'];
    }
    return const [];
  }

  List<String> _grammarCandidates(String id) {
    if (Platform.isMacOS) {
      return [
        'libtree-sitter-$id.dylib',
        '@executable_path/../Frameworks/libtree-sitter-$id.dylib',
      ];
    }
    if (Platform.isLinux) {
      return linuxCandidates(
        'libtree-sitter-$id.so',
        File(Platform.resolvedExecutable).parent.path,
      );
    }
    if (Platform.isWindows) {
      return ['tree-sitter-$id.dll', 'libtree-sitter-$id.dll'];
    }
    return const [];
  }

  /// Linux load candidates for [fileName], bundled-path first.
  ///
  /// The Linux release ships natives under `<exeDir>/lib/` (AppImage / tar
  /// bundle). `dlopen`-by-soname does not honour the executable's `$ORIGIN/lib`
  /// RUNPATH, so the explicit bundled path is tried before the bare soname
  /// (which covers a system or app-support install).
  @visibleForTesting
  static List<String> linuxCandidates(String fileName, String exeDir) => [
    '$exeDir/lib/$fileName',
    fileName,
    '$fileName.0',
  ];

  DynamicLibrary? _tryOpen(List<String> candidates) {
    for (final candidate in candidates) {
      try {
        return DynamicLibrary.open(candidate);
      } on ArgumentError {
        // Library not present at this path — try the next candidate.
        continue;
      } catch (_) {
        // Any other load failure (bad arch, missing symbol set): degrade.
        continue;
      }
    }
    return null;
  }
}
