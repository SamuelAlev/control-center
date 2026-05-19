/// A single file or folder hit from a server-side repo file search
/// (`repos.searchFiles`).
///
/// This is the **web-safe domain/wire type** for file search. The RPC server
/// owns the native search (the `cc_natives` `FileSearch` over the repo checkouts
/// it owns) and emits these via `toJson`; the thin client reconstructs them via
/// `fromJson`. Keeping this type in the shared kernel means neither the desktop
/// nor the web client ever depends on the native `cc_natives` package for file
/// search — the search runs on the server, on every platform, over RPC.
class FileSearchHit {
  /// Creates a [FileSearchHit].
  const FileSearchHit({
    required this.absolutePath,
    required this.relativePath,
    required this.rootPath,
    required this.isDirectory,
    this.score = 0,
  });

  /// Decodes a hit from its wire map (tolerant of missing fields).
  factory FileSearchHit.fromJson(Map<String, dynamic> json) => FileSearchHit(
        absolutePath: json['absolutePath'] as String? ?? '',
        relativePath: json['relativePath'] as String? ?? '',
        rootPath: json['rootPath'] as String? ?? '',
        isDirectory: json['isDirectory'] as bool? ?? false,
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );

  /// Absolute path on disk (server-side).
  final String absolutePath;

  /// Path relative to the search root that produced this hit.
  final String relativePath;

  /// The root path the search was rooted at.
  final String rootPath;

  /// True when the hit is a directory rather than a file.
  final bool isDirectory;

  /// Higher is better. 0 means "match exists but no scoring info".
  final double score;

  /// Encodes the hit to its wire map.
  Map<String, dynamic> toJson() => {
        'absolutePath': absolutePath,
        'relativePath': relativePath,
        'rootPath': rootPath,
        'isDirectory': isDirectory,
        'score': score,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileSearchHit &&
          absolutePath == other.absolutePath &&
          relativePath == other.relativePath &&
          rootPath == other.rootPath &&
          isDirectory == other.isDirectory &&
          score == other.score;

  @override
  int get hashCode =>
      Object.hash(absolutePath, relativePath, rootPath, isDirectory, score);
}
