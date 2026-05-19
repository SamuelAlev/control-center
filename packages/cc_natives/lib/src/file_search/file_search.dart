import 'package:meta/meta.dart';

/// One file or folder hit returned from a [FileSearch].
@immutable
class FileSearchHit {
  /// Creates a [FileSearchHit].
  const FileSearchHit({
    required this.absolutePath,
    required this.relativePath,
    required this.rootPath,
    required this.isDirectory,
    this.score = 0,
  });

  /// Absolute path on disk.
  final String absolutePath;

  /// Path relative to the search root that produced this hit.
  final String relativePath;

  /// The root path the search was rooted at.
  final String rootPath;

  /// True when the hit is a directory rather than a file.
  final bool isDirectory;

  /// Higher is better. 0 means "match exists but no scoring info."
  final double score;
}

/// Pluggable file finder used by the composer's `@<path>` source.
///
/// Implementations:
/// - `DartFileSearch`: pure-Dart `Directory.list()` with cache + fuzzy filter.
///   Works today, no native code. Adequate for <50k file workspaces.
/// - `FffFileSearch`: FFI binding to fff (Rust). Drop-in once the dylib is
///   built and bundled — see `lib/core/infrastructure/file_search/fff_file_search.dart`.
abstract class FileSearch {
  /// Search every root for entries matching [query]. Results stream in as
  /// they're discovered. Implementations should cap their own per-root list.
  ///
  /// [query] is interpreted as a fuzzy substring against the relative path
  /// (case-insensitive). Empty query yields recently-known entries.
  Stream<List<FileSearchHit>> search({
    required List<String> roots,
    required String query,
    int limit = 25,
  });

  /// Streams the full cached entry list for [roots] (no filtering).
  ///
  /// Empty-query tree mode: returns every entry the implementation knows
  /// about (directories and files) with score `0`, capped per implementation.
  /// Used to render an unfiltered explorer tree.
  Stream<List<FileSearchHit>> listEntries({
    required List<String> roots,
    int limit = 50000,
  });

  /// Prime the cache for these roots (called once when the composer opens).
  /// Implementations may no-op.
  Future<void> warmUp(List<String> roots) async {}

  /// Drop cached state for these roots.
  void invalidate(List<String> roots) {}
}
