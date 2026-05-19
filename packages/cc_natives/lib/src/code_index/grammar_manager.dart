import 'dart:convert';
import 'dart:io';

import 'package:cc_natives/src/code_index/embedded_queries.dart';
import 'package:cc_natives/src/native_library_paths.dart'
    show dartBuildBundleLibDir;
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

/// Download source for a grammar's natives, with REQUIRED SHA-256 checksums.
///
/// When no source is configured, [GrammarManager.install] only resolves
/// locally-present libs (e.g. produced by `scripts/natives/build_tree_sitter.sh`)
/// and returns null if absent — which the indexer treats as a broken install
/// and throws on, since every recognised language ships a grammar.
///
/// The checksums are REQUIRED, not optional. This downloads executable dylibs
/// and `dlopen`s them: an unpinned entry is a supply-chain hole, and it was
/// inconsistent with the rest of the project (checksum-pinned rig images, a
/// fail-closed skills scanner, digest-pinned OCI images). Both were nullable
/// and verification was skipped when null, so a source could silently opt out
/// of being verified at all.
class GrammarSource {
  /// Creates a [GrammarSource]. Both checksums are required — see the class
  /// doc for why an unpinned download is refused rather than trusted.
  const GrammarSource({
    required this.runtimeUrl,
    required this.grammarUrl,
    required this.runtimeSha256,
    required this.grammarSha256,
  }) : assert(
         runtimeSha256.length == 64 && grammarSha256.length == 64,
         'SHA-256 digests are 64 hex characters',
       );

  /// Remote URL for the tree-sitter runtime library.
  final String runtimeUrl;

  /// Remote URL for the grammar library.
  final String grammarUrl;

  /// Expected SHA-256 hex digest of the runtime download.
  final String runtimeSha256;

  /// Expected SHA-256 hex digest of the grammar download.
  final String grammarSha256;
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
  }) : _dio = dio,
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
  ///      into (e.g. the standalone `cc_server` data dir),
  ///   3. the `dart build cli` bundle `lib/` dir — where the cc_server build
  ///      hook bundles the natives beside libsqlite3 and
  ///   4. the dir the release packaging bundles the natives into (macOS
  ///      `Contents/Frameworks/`, Linux `<exeDir>/lib/`, Windows beside the
  ///      `.exe`).
  /// Without the bundled fallbacks the code graph stays dark in a packaged
  /// build even though the libs ship inside it, because this resolver — not the
  /// loader's candidate list — gates whether indexing runs.
  Future<List<String>> _searchDirs() async {
    final grammars = (await _dir()).path;
    return [
      grammars,
      p.dirname(grammars),
      dartBuildBundleLibDir(),
      ..._bundledLibDirs(),
    ];
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

  /// Loads the tree-sitter `.scm` query for [queryId]: an on-disk
  /// `<queryId>.scm` beside the grammar lib wins — the canonical files from
  /// `scripts/natives/queries/` are staged there by `build_tree_sitter.sh` in
  /// dev and by the release packaging in prod, so both run the same real
  /// files. Falls back to [embeddedTreeSitterQueries] (generated from those
  /// same files by `tool/gen_embedded_queries.dart`, compiled into every
  /// host) when no file is present. Returns null only for a language this
  /// package has no query for.
  Future<String?> loadQuery(String queryId) async {
    final fileName = '$queryId.scm';
    for (final dirPath in await _searchDirs()) {
      final file = File(p.join(dirPath, fileName));
      if (file.existsSync()) {
        return file.readAsString();
      }
    }
    final embedded = embeddedTreeSitterQueries[queryId];
    if (embedded != null) {
      return embedded;
    }
    _log?.call(
      'GrammarManager',
      'no query "$fileName" on disk and none embedded',
    );
    return null;
  }

  /// Stamps of every extraction artifact this manager can see: the embedded
  /// `.scm` query map (sorted key → content hash) plus `name|mtime|size` of
  /// every on-disk `.scm` file and tree-sitter library in the search dirs.
  ///
  /// Feeds the code indexer's fingerprint: editing a query on disk, staging a
  /// new grammar, or shipping different embedded queries changes the stamps,
  /// which invalidates every index checkpoint — so a previously-unindexable
  /// language gets indexed and an edited query re-extracts, automatically.
  Future<List<String>> artifactStamps() async {
    // Content hash, not `hashCode`: String.hashCode is not guaranteed stable
    // across VM versions and a spurious change here re-indexes every repo.
    final stamps = <String>[
      for (final entry
          in (embeddedTreeSitterQueries.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))))
        'embedded:${entry.key}|${sha256.convert(utf8.encode(entry.value))}',
    ];
    for (final dirPath in await _searchDirs()) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        continue;
      }
      List<FileSystemEntity> entries;
      try {
        entries = dir.listSync(followLinks: false);
      } on FileSystemException {
        continue;
      }
      for (final entity in entries) {
        if (entity is! File) {
          continue;
        }
        final name = p.basename(entity.path);
        final isQuery = name.endsWith('.scm');
        final isGrammar =
            name.contains('tree-sitter') &&
            (name.endsWith('.dylib') ||
                name.endsWith('.so') ||
                name.endsWith('.dll'));
        if (!isQuery && !isGrammar) {
          continue;
        }
        try {
          final stat = entity.statSync();
          stamps.add(
            '$name|${stat.modified.microsecondsSinceEpoch}|${stat.size}',
          );
        } on FileSystemException {
          continue;
        }
      }
    }
    stamps.sort();
    return stamps;
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
  /// given and the libs are missing, downloads + verifies them.
  ///
  /// Returns null when nothing is installed and no source is provided. That is a
  /// PROBE RESULT, not a licence to degrade: every language the walker
  /// recognises ships a grammar, so the indexer turns null into a hard failure
  /// naming the language.
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
    String expectedSha256,
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
    // Always verified — there is no "no checksum configured" path any more.
    final actual = sha256.convert(await File(dest).readAsBytes()).toString();
    if (actual.toLowerCase() != expectedSha256.toLowerCase()) {
      // Delete the unverified bytes: leaving them on disk invites a later
      // resolve() from picking them up as a locally-present lib.
      try {
        await File(dest).delete();
      } on Object {
        // Best-effort.
      }
      throw GrammarInstallException(
        'checksum mismatch for $url (expected $expectedSha256, got $actual)',
      );
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
