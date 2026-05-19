/// One file's slice of a unified diff.
class DiffSegment {
  /// Creates a [DiffSegment].
  const DiffSegment({required this.path, required this.text});
  /// Path of the file as named in the diff header.
  final String path;
  /// Raw text of this file's hunks, including the `diff --git` header line.
  final String text;
}

/// Splits a unified diff produced by `git format-patch`-style output into
/// per-file [DiffSegment]s.
class DiffSegmenter {
  /// Creates a const [DiffSegmenter].
  const DiffSegmenter();

  /// Returns the list of files touched by [diff], in encounter order.
  List<String> fileList(String diff) =>
      segments(diff).map((s) => s.path).toList(growable: false);

  /// Splits [diff] into per-file segments.
  List<DiffSegment> segments(String diff) {
    if (diff.isEmpty) return const [];
    final lines = diff.split('\n');
    final out = <DiffSegment>[];
    String? currentPath;
    final currentText = StringBuffer();
    for (final line in lines) {
      if (line.startsWith('diff --git ')) {
        if (currentPath != null) {
          out.add(DiffSegment(
            path: currentPath,
            text: currentText.toString(),
          ));
          currentText.clear();
        }
        currentPath = _extractPath(line) ?? '<unknown>';
      }
      if (currentPath != null) {
        currentText.writeln(line);
      }
    }
    if (currentPath != null) {
      out.add(DiffSegment(path: currentPath, text: currentText.toString()));
    }
    return out;
  }

  String? _extractPath(String header) {
    // "diff --git a/foo/bar b/foo/bar"
    final parts = header.split(' ');
    if (parts.length < 4) return null;
    final b = parts.last;
    if (b.startsWith('b/')) return b.substring(2);
    return null;
  }
}
