/// Registry mapping source-file extensions to tree-sitter language ids.
///
/// The `languageId` is used three ways, so it must match the grammar build:
///   1. grammar entrypoint symbol  `tree_sitter_<languageId>`
///   2. grammar library filename   `libtree-sitter-<languageId>.<ext>`
///   3. query file                 `<queryId>.scm`, resolved beside the grammar
///      lib (see `GrammarManager.loadQuery`; via [queryIdFor], so `tsx` reuses
///      the `typescript` query).
///
/// Adding a language = add its extensions here + a grammar lib + a `.scm` query
/// (built/staged by `scripts/natives/build_tree_sitter.sh`).
library;

/// Extension (without leading dot, lowercased) → languageId.
const Map<String, String> kLanguageByExtension = {
  'dart': 'dart',
  'js': 'javascript',
  'jsx': 'javascript',
  'mjs': 'javascript',
  'cjs': 'javascript',
  'ts': 'typescript',
  'mts': 'typescript',
  'cts': 'typescript',
  'tsx': 'tsx',
  'php': 'php',
  'py': 'python',
  'pyi': 'python',
  'pyw': 'python',
  'rs': 'rust',
  'zig': 'zig',
  'c': 'c',
  'h': 'c',
  'cpp': 'cpp',
  'cc': 'cpp',
  'cxx': 'cpp',
  'hpp': 'cpp',
  'hh': 'cpp',
  'hxx': 'cpp',
  'go': 'go',
  'java': 'java',
  'rb': 'ruby',
  'cs': 'c_sharp',
  'swift': 'swift',
  'kt': 'kotlin',
  'kts': 'kotlin',
  'r': 'r',
  's': 'asm',
  'asm': 'asm',
  // `.m` is also Objective-C. MATLAB is the shipped grammar, so a colliding
  // ObjC file is indexed as MATLAB rather than left unparsed.
  'm': 'matlab',
  'ads': 'ada',
  'adb': 'ada',
  'ada': 'ada',
};

/// languageId → query asset id. Defaults to the languageId itself; `tsx`
/// reuses the `typescript` query (same node types for the captured constructs).
const Map<String, String> _queryIdOverrides = {'tsx': 'typescript'};

/// The `.scm` query id to load for [languageId].
String queryIdFor(String languageId) =>
    _queryIdOverrides[languageId] ?? languageId;

/// Resolves the languageId for a file path by its extension, or null when the
/// extension isn't indexable.
String? languageIdForPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) {
    return null;
  }
  return kLanguageByExtension[path.substring(dot + 1).toLowerCase()];
}
