/// A single fuzzy file-search hit.
class FileSearchMatch {
  /// Creates a [FileSearchMatch].
  const FileSearchMatch({
    required this.path,
    this.isDirectory = false,
    this.score = 0,
  });

  /// Path of the matched file (relative to the searched root when possible).
  final String path;

  /// Whether the hit is a directory (rendered with a trailing `/`).
  final bool isDirectory;

  /// Relevance score — higher is better. Implementations define the scale;
  /// only the ordering is meaningful to callers.
  final double score;
}

/// Fuzzy filename search over a directory tree.
///
/// The kernel port behind the `search_files` tool. Control Center implements
/// it over `cc_natives` (the Rust `fff` finder with a pure-Dart fallback);
/// tests inject fakes. Implementations skip VCS/build directories and never
/// read file contents — this is a name-relevance ranking, not a grep.
abstract interface class FileSearchPort {
  /// Returns the best [limit] matches for [query] under [root], ranked by
  /// descending relevance.
  Future<List<FileSearchMatch>> search(
    String query, {
    required String root,
    int limit,
  });
}
