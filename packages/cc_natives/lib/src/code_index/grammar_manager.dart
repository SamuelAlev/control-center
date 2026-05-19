import 'dart:io';

import 'package:cc_natives/src/native_runtime.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// Resolved on-disk paths to the tree-sitter natives for a language.
class GrammarPaths {
/// Creates a [GrammarPaths] with the given paths.
  const GrammarPaths({required this.runtimePath, required this.grammarPath});

  /// Absolute path to `libtree-sitter` (the runtime).
  final String runtimePath;

  /// Absolute path to the `tree-sitter-<lang>` grammar library.
  final String grammarPath;
}

/// Optional download source for a grammar's natives (with SHA-256 checksums).
/// When null, [GrammarManager.install] only resolves locally-present libs
/// (e.g. produced by `scripts/natives/build_tree_sitter.sh`) and returns null if
/// absent — the indexer then skips gracefully.
class GrammarSource {
/// Creates a [GrammarSource] with optional SHA-256 checksums.
  const GrammarSource({
    required this.runtimeUrl,
    required this.grammarUrl,
    this.runtimeSha256,
    this.grammarSha256,
  });
/// Remote URL for the tree-sitter runtime library.
  final String runtimeUrl;
/// Remote URL for the grammar library.
  final String grammarUrl;
/// Expected SHA-256 hex digest of the runtime download.
  final String? runtimeSha256;
/// Expected SHA-256 hex digest of the grammar download.
  final String? grammarSha256;
}

/// Thrown when an install fails (download error or checksum mismatch).
class GrammarInstallException implements Exception {
/// Creates a [GrammarInstallException] with the given message.
  GrammarInstallException(this.message);
/// The error message.
  final String message;
  @override
  String toString() => 'GrammarInstallException: $message';
}

/// Owns the on-disk lifecycle of tree-sitter native libraries under
/// `<root>/grammars/`. Mirrors `EmbeddingModelManager` (download → verify →
/// resolve), with the deliberate addition of SHA-256 verification.
class GrammarManager {
  /// Creates a [GrammarManager].
  ///
  /// [dio] downloads grammar natives; [grammarsDir] resolves the install
  /// directory (`<app-support>/grammars`, populated by
  /// `scripts/natives/build_tree_sitter.sh` in dev or by [install] when
  /// downloaded). [onLog] receives diagnostics; defaults to silent. The host
  /// injects all three so `cc_natives` stays a leaf package.
  GrammarManager({
    required Dio dio,
    required NativeDirResolver grammarsDir,
    NativeLog? onLog,
  })  : _dio = dio,
        _grammarsDir = grammarsDir,
        _log = onLog;

  final Dio _dio;
  final NativeDirResolver _grammarsDir;
  final NativeLog? _log;

  Future<Directory> _dir() => _grammarsDir();

  String get _runtimeFileName {
    if (Platform.isMacOS) {
      return 'libtree-sitter.dylib';
    }
    if (Platform.isWindows) {
      return 'tree-sitter.dll';
    }
    return 'libtree-sitter.so';
  }

  String _grammarFileName(String languageId) {
    if (Platform.isMacOS) {
      return 'libtree-sitter-$languageId.dylib';
    }
    if (Platform.isWindows) {
      return 'tree-sitter-$languageId.dll';
    }
    return 'libtree-sitter-$languageId.so';
  }

  /// Directories searched (in order) for tree-sitter natives and their `.scm`
  /// queries:
  ///   1. the `grammars/` dir beside `control_center.db` (populated by
  ///      `scripts/natives/build_tree_sitter.sh` in dev or by [install]),
  ///   2. the data-dir root itself — a flat layout some hosts stage natives
  ///      into (e.g. the standalone `cc_server` data dir), and
  ///   3. the dir the release packaging bundles the natives into (macOS
  ///      `Contents/Frameworks/`, Linux `<exeDir>/lib/`, Windows beside the
  ///      `.exe`).
  /// Without the bundled fallback the code graph stays dark in a packaged build
  /// even though the libs ship inside it, because this resolver — not the
  /// loader's candidate list — gates whether indexing runs.
  Future<List<String>> _searchDirs() async {
    final grammars = (await _dir()).path;
    return [grammars, p.dirname(grammars), ..._bundledLibDirs()];
  }

  /// Returns paths to locally-present natives for [languageId], or null.
  Future<GrammarPaths?> resolve(String languageId) async {
    final runtimeName = _runtimeFileName;
    final grammarName = _grammarFileName(languageId);
    for (final dirPath in await _searchDirs()) {
      final runtime = File(p.join(dirPath, runtimeName));
      final grammar = File(p.join(dirPath, grammarName));
      if (runtime.existsSync() && grammar.existsSync()) {
        return GrammarPaths(
          runtimePath: runtime.path,
          grammarPath: grammar.path,
        );
      }
    }
    return null;
  }

  /// Loads the tree-sitter `.scm` query named `<queryId>.scm` from the same
  /// dirs natives resolve from ([_searchDirs]) — the query travels beside its
  /// grammar lib in dev (`build_tree_sitter.sh`) and in release bundles
  /// (staged by `scripts/release/*`). Returns null when no such file is found,
  /// so the indexer can skip the language gracefully rather than crash.
  Future<String?> loadQuery(String queryId) async {
    final fileName = '$queryId.scm';
    for (final dirPath in await _searchDirs()) {
      final file = File(p.join(dirPath, fileName));
      if (file.existsSync()) {
        return file.readAsString();
      }
    }
    _log?.call('GrammarManager', 'no query file "$fileName" found on disk');
    return null;
  }

  /// Directories the release packaging bundles the tree-sitter natives into,
  /// resolved relative to the running executable. Mirrors the platform
  /// candidates in `TreeSitterLoader`. Empty in unsupported/test environments,
  /// where the entries simply don't exist on disk.
  List<String> _bundledLibDirs() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    if (Platform.isMacOS) {
      // <app>/Contents/MacOS/<exe> → <app>/Contents/Frameworks/
      return [p.normalize(p.join(exeDir, '..', 'Frameworks'))];
    }
    if (Platform.isLinux) {
      return [p.join(exeDir, 'lib')];
    }
    if (Platform.isWindows) {
      return [exeDir];
    }
    return const [];
  }

  /// Ensures the natives for [languageId] are present. If already installed (or
  /// bundled via the build script), returns their paths. If a [source] is
  /// given and the libs are missing, downloads + verifies them. Returns null
  /// when nothing is installed and no source is provided — the caller then
  /// skips indexing (graceful no-op).
  Future<GrammarPaths?> install(
    String languageId, {
    GrammarSource? source,
    void Function(double progress, String phase)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final existing = await resolve(languageId);
    if (existing != null) {
      onProgress?.call(1, 'ready');
      return existing;
    }
    if (source == null) {
      return null;
    }

    final dir = await _dir();
    final runtimePath = p.join(dir.path, _runtimeFileName);
    final grammarPath = p.join(dir.path, _grammarFileName(languageId));
    onProgress?.call(0, 'downloading');

    try {
      await _download(
        source.runtimeUrl,
        runtimePath,
        source.runtimeSha256,
        cancelToken,
        (p) => onProgress?.call(p * 0.5, 'downloading'),
      );
      await _download(
        source.grammarUrl,
        grammarPath,
        source.grammarSha256,
        cancelToken,
        (p) => onProgress?.call(0.5 + p * 0.5, 'downloading'),
      );
    } catch (e) {
      for (final path in [runtimePath, grammarPath]) {
        final f = File(path);
        if (f.existsSync()) {
          await f.delete();
        }
      }
      if (e is GrammarInstallException) {
        rethrow;
      }
      throw GrammarInstallException('grammar download failed: $e');
    }

    onProgress?.call(1, 'ready');
    return resolve(languageId);
  }

  Future<void> _download(
    String url,
    String dest,
    String? expectedSha256,
    CancelToken? cancelToken,
    void Function(double) onProgress,
  ) async {
    await _dio.download(
      url,
      dest,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress((received / total).clamp(0.0, 1.0));
        }
      },
      options: Options(followRedirects: true, responseType: ResponseType.bytes),
    );
    if (expectedSha256 != null) {
      final actual = sha256.convert(await File(dest).readAsBytes()).toString();
      if (actual.toLowerCase() != expectedSha256.toLowerCase()) {
        throw GrammarInstallException(
          'checksum mismatch for $url (expected $expectedSha256, got $actual)',
        );
      }
    }
  }

  /// Removes all installed grammar natives.
  Future<void> uninstall() async {
    final dir = await _dir();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      _log?.call('GrammarManager', 'removed installed tree-sitter natives');
    }
  }
}
