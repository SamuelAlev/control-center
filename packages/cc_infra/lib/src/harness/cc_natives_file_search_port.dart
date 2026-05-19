import 'package:cc_harness/tools.dart';
import 'package:cc_natives/cc_natives.dart';

/// The Control Center implementation of the kernel's [FileSearchPort],
/// backed by cc_natives' fff (the Rust fuzzy engine).
///
/// The server passes its long-lived [FffFileSearch] instance in so the harness
/// tools share fff's per-root scan caches with the IDE surfaces.
///
/// `libfff_c` is REQUIRED: a load failure surfaces as [FffUnavailable] on the
/// tool call rather than degrading to the pure-Dart walker. The blanket
/// try/catch that used to swap in [DartFileSearch] also swallowed genuine
/// search bugs (a bad root, a permission error) into a slow silent walk, and
/// `cc_server` refuses to boot without the dylib anyway, so a degrade here
/// could only ever mask a broken install.
class CcNativesFileSearchPort implements FileSearchPort {
  /// Creates the adapter. [fileSearch] defaults to [FffFileSearch]; inject
  /// the server's shared instance when one exists.
  CcNativesFileSearchPort({FileSearch? fileSearch})
    : _fileSearch = fileSearch ?? FffFileSearch();

  final FileSearch _fileSearch;

  @override
  Future<List<FileSearchMatch>> search(
    String query, {
    required String root,
    int limit = 25,
  }) async {
    final hits = await _fileSearch
        .search(roots: [root], query: query, limit: limit)
        .last;
    return [
      for (final hit in hits)
        FileSearchMatch(
          path: hit.relativePath,
          isDirectory: hit.isDirectory,
          score: hit.score,
        ),
    ];
  }
}
