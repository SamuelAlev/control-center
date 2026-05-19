import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:control_center/core/infrastructure/code_index/code_languages.dart';
import 'package:control_center/core/infrastructure/code_index/grammar_manager.dart';
import 'package:control_center/core/infrastructure/code_index/source_file_walker.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/code_graph/data/extraction/code_extractor.dart'
    show ExtractionResult;
import 'package:control_center/features/code_graph/data/extraction/extraction_isolate.dart';
import 'package:control_center/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:control_center/features/code_graph/domain/services/code_indexer.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Default [CodeIndexer]: enumerate source files, group them by language
/// (detected from extension), then for each language whose tree-sitter natives
/// are installed, skip unchanged files (content hash), parse + extract each
/// changed file in a worker isolate, and ingest into the [CodeGraphRepository].
/// Finally prune deleted files and resolve cross-file references repo-wide.
///
/// Degrades gracefully: languages without natives are skipped; if no language
/// has natives at all, [indexRepo] returns [CodeIndexResult.skipped] without
/// touching the index.
class DefaultCodeIndexer implements CodeIndexer {
  /// Creates a [DefaultCodeIndexer].
  DefaultCodeIndexer({
    required CodeGraphRepository repository,
    GrammarManager? grammarManager,
    SourceFileWalker? walker,
    Future<String> Function(String queryId)? queryLoader,
  }) : _repository = repository,
       _grammarManager = grammarManager ?? GrammarManager(),
       _walker = walker ?? const SourceFileWalker(),
       _queryLoader = queryLoader ?? _defaultQueryLoader;

  final CodeGraphRepository _repository;
  final GrammarManager _grammarManager;
  final SourceFileWalker _walker;
  final Future<String> Function(String queryId) _queryLoader;

  static Future<String> _defaultQueryLoader(String queryId) =>
      rootBundle.loadString('assets/code_index/queries/$queryId.scm');

  @override
  Future<CodeIndexResult> indexRepo({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    void Function(CodeIndexProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final files = await _walker.walk(repoPath);
    final current = {for (final file in files) file.relativePath};

    // Group walked files by detected language.
    final byLanguage = <String, List<SourceFile>>{};
    for (final file in files) {
      final languageId = languageIdForPath(file.relativePath);
      if (languageId == null) {
        continue;
      }
      (byLanguage[languageId] ??= <SourceFile>[]).add(file);
    }

    final existing = await _repository.fileHashes(workspaceId, repoId);
    final unavailable = <String>[];
    var indexed = 0;
    var skipped = 0;
    var symbols = 0;
    var edges = 0;
    var failed = 0;
    var anyNative = false;

    outer:
    for (final entry in byLanguage.entries) {
      final languageId = entry.key;
      final grammar = await _grammarManager.install(languageId);
      if (grammar == null) {
        unavailable.add(languageId);
        continue;
      }
      anyNative = true;
      final query = await _queryLoader(queryIdFor(languageId));

      for (final file in entry.value) {
        if (isCancelled?.call() ?? false) {
          break outer;
        }
        final hash = await _walker.hashFile(file.absolutePath);
        if (existing[file.relativePath] == hash) {
          skipped++;
          continue;
        }
        String source;
        try {
          source = await File(file.absolutePath).readAsString();
        } catch (_) {
          continue;
        }
        final request = ExtractionRequest(
          workspaceId: workspaceId,
          repoId: repoId,
          filePath: file.relativePath,
          source: source,
          languageId: languageId,
          querySource: query,
          runtimePath: grammar.runtimePath,
          grammarPath: grammar.grammarPath,
        );
        ExtractionResult result;
        try {
          // Bound each file's parse so a pathological file can't consume the
          // whole 30-minute step budget, and surface (rather than silently
          // swallow) isolate crashes / grammar failures.
          result = await Isolate.run(() => extractFileInIsolate(request))
              .timeout(const Duration(seconds: 30));
        } on TimeoutException {
          failed++;
          AppLog.w(
            'CodeIndexer',
            'Timed out parsing ${file.relativePath} (30s); skipping',
          );
          continue;
        } on Object catch (e) {
          failed++;
          AppLog.w(
            'CodeIndexer',
            'Failed to parse ${file.relativePath}: $e; skipping',
          );
          continue;
        }
        await _repository.ingestFile(
          workspaceId: workspaceId,
          repoId: repoId,
          filePath: file.relativePath,
          contentHash: hash,
          symbols: result.symbols,
          edges: result.edges,
          language: languageId,
        );
        indexed++;
        symbols += result.symbols.length;
        edges += result.edges.length;
        onProgress?.call(
          CodeIndexProgress(
            filesIndexed: indexed,
            totalFiles: files.length,
            symbols: symbols,
            edges: edges,
          ),
        );
      }
    }

    // No supported files had installable natives → nothing was indexed.
    if (byLanguage.isNotEmpty && !anyNative) {
      return CodeIndexResult.skipped(
        'tree-sitter natives not installed for: ${byLanguage.keys.join(', ')}',
      );
    }
    if (unavailable.isNotEmpty) {
      AppLog.i(
        'CodeIndexer',
        'skipped languages (natives missing): ${unavailable.join(', ')}',
      );
    }
    if (failed > 0) {
      AppLog.w(
        'CodeIndexer',
        'skipped $failed file(s) due to parse timeout or extraction error',
      );
    }

    // Prune files that no longer exist on disk (any language).
    final removed = existing.keys
        .where((path) => !current.contains(path))
        .toList();
    if (removed.isNotEmpty) {
      await _repository.deleteFiles(workspaceId, repoId, removed);
    }

    // Bind cross-file references now that every file's symbols are present.
    final resolved = await _repository.resolvePendingReferences(
      workspaceId,
      repoId,
    );

    return CodeIndexResult(
      filesIndexed: indexed,
      filesSkipped: skipped,
      symbols: symbols,
      edges: edges,
      removedFiles: removed.length,
      resolvedReferences: resolved,
      nativeAvailable: anyNative || byLanguage.isEmpty,
    );
  }
}
