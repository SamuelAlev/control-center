import 'dart:async';
import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/core/domain/ports/git_command_port.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/pr_review/data/services/pr_clone_manager.dart';
import 'package:control_center/features/pr_review/data/sources/git_diff_z_parser.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:control_center/shared/utils/diff_parser.dart';

/// [PrDiffSource] backed by a local blobless git clone.
///
/// Used when a PR exceeds GitHub's 3 000-file API cap. After cloning/fetching:
/// 1. Emits the file tree immediately (empty patches) from `git diff --numstat`.
/// 2. Streams patches progressively from `git diff --no-color`.
class LocalGitPrDiffSource implements PrDiffSource {
  /// Creates a [LocalGitPrDiffSource] used when a PR exceeds GitHub's file cap,
  /// falling back to a local blobless clone for diffs.
  const LocalGitPrDiffSource({
    required GitCommandPort git,
    required WorkspaceFilesystemPort filesystem,
    required String githubToken,
    RiftClient? rift,
  }) : _git = git,
       _filesystem = filesystem,
       _githubToken = githubToken,
       _rift = rift;

  final GitCommandPort _git;
  final WorkspaceFilesystemPort _filesystem;
  final String _githubToken;
  final RiftClient? _rift;

  @override
  Stream<PrFilesLoad> watchFiles(PrSourceRequest req) async* {
    final manager = _buildManager(req);

    // 1. Ensure clone + fetch.
    await for (final progress in manager.ensureCloneAndFetch(
      prNumber: req.prNumber,
      baseRef: req.baseRef,
      headSha: req.headSha,
    )) {
      if (progress.phase == PrClonePhase.error) {
        yield PrFilesLoad(
          files: const [],
          error: progress.error ?? 'Clone failed',
          clonePhase: ClonePhase.error,
        );
        return;
      }
      yield PrFilesLoad(
        files: const [],
        clonePhase: _mapPhase(progress.phase),
        cloneMessage: progress.message,
      );
    }

    final clonePath = await manager.clonePath();
    final mergeBase = await _resolveMergeBase(
      clonePath,
      req.baseRef,
      req.prNumber,
    );
    if (mergeBase == null) {
      yield PrFilesLoad(
        files: const [],
        error: 'Could not resolve merge base for PR #${req.prNumber}',
        clonePhase: ClonePhase.error,
      );
      return;
    }

    // 2. Compute the file tree + patches, surfacing git's progress as we go. A
    //    `git diff` against a blobless clone lazily fetches every changed blob
    //    from the promisor remote at this point — that network work is
    //    otherwise silent and makes the UI look frozen, so we stream its
    //    stderr progress (e.g. "Receiving objects: 45% …") to the UI.
    final headRef = 'refs/pr/${req.prNumber}/head';
    yield* _computeFilesWithProgress(clonePath, mergeBase, headRef);
  }

  /// Builds the file list and fills patches, emitting [ClonePhase.computing]
  /// progress messages from git's stderr throughout. Runs the work in a
  /// detached future and bridges progress + results through a controller so the
  /// lazy blob fetch never blocks silently.
  Stream<PrFilesLoad> _computeFilesWithProgress(
    String clonePath,
    String mergeBase,
    String headRef,
  ) {
    final controller = StreamController<PrFilesLoad>();

    Future<void> work() async {
      void emitProgress(String line) {
        final msg = _sanitize(line);
        if (msg.isNotEmpty && !controller.isClosed) {
          controller.add(
            PrFilesLoad(
              files: const [],
              clonePhase: ClonePhase.computing,
              cloneMessage: msg,
            ),
          );
        }
      }

      // Build the file tree (numstat + name-status). The numstat diff triggers
      // the bulk lazy blob fetch on a blobless clone.
      List<PrFile> files;
      try {
        files = await _buildFileList(
          clonePath,
          mergeBase,
          headRef,
          onProgress: emitProgress,
        );
      } catch (e, st) {
        AppLog.e('LocalGitPrDiffSource', 'file list build failed: $e', e, st);
        if (!controller.isClosed) {
          controller.add(
            PrFilesLoad(
              files: const [],
              error: e,
              clonePhase: ClonePhase.error,
            ),
          );
          await controller.close();
        }
        return;
      }

      // Emit the tree immediately (stats, no patches) so it renders fast.
      if (!controller.isClosed) {
        controller.add(
          PrFilesLoad(
            files: List<PrFile>.unmodifiable(files),
            clonePhase: ClonePhase.computing,
          ),
        );
      }

      // Fill patches from the full diff. Blobs were fetched by the numstat pass
      // above, so this is usually fast.
      try {
        final result = await _git.run(
          ['diff', '--no-color', '-M', '$mergeBase...$headRef'],
          workdir: clonePath,
          onProgress: emitProgress,
        );
        if (!result.isSuccess) {
          throw StateError(
            'git diff failed (${result.exitCode}): ${result.stderr}',
          );
        }
        final patches = extractAllFilePatches(result.stdout);
        final updated = [
          for (final f in files)
            PrFile(
              filename: f.filename,
              status: f.status,
              additions: f.additions,
              deletions: f.deletions,
              patch:
                  patches[f.filename] ??
                  patches[f.previousFilename ?? ''] ??
                  '',
              previousFilename: f.previousFilename,
              viewerViewedState: f.viewerViewedState,
            ),
        ];
        if (!controller.isClosed) {
          controller.add(
            PrFilesLoad(
              files: List<PrFile>.unmodifiable(updated),
              isComplete: true,
              clonePhase: ClonePhase.ready,
            ),
          );
        }
      } catch (e, st) {
        AppLog.e('LocalGitPrDiffSource', 'patch streaming failed: $e', e, st);
        // The tree is usable without patches — surface it as ready.
        if (!controller.isClosed) {
          controller.add(
            PrFilesLoad(
              files: List<PrFile>.unmodifiable(files),
              isComplete: true,
              clonePhase: ClonePhase.ready,
            ),
          );
        }
      } finally {
        if (!controller.isClosed) {
          await controller.close();
        }
      }
    }

    unawaited(work());
    return controller.stream;
  }

  /// Strips ANSI escape codes and the "remote: " prefix from a git progress
  /// line so it renders cleanly in the progress card.
  static String _sanitize(String line) {
    final noAnsi = line.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
    return noAnsi.replaceFirst(RegExp(r'^remote:\s*'), '').trim();
  }

  @override
  Stream<List<PrCommit>> watchCommits(PrSourceRequest req) async* {
    final manager = _buildManager(req);
    final clonePath = await manager.clonePath();

    if (!_isCloned(clonePath)) {
      yield const [];
      return;
    }

    final headRef = 'refs/pr/${req.prNumber}/head';
    final mergeBase = await _resolveMergeBase(
      clonePath,
      req.baseRef,
      req.prNumber,
    );
    if (mergeBase == null) {
      yield const [];
      return;
    }

    final result = await _git.run([
      'log',
      '--format=%H\x1f%s\x1f%an\x1f%ae\x1f%aI',
      '$mergeBase..$headRef',
    ], workdir: clonePath);

    if (!result.isSuccess) {
      yield const [];
      return;
    }

    final commits = <PrCommit>[];
    for (final line in result.stdout.trim().split('\n')) {
      if (line.isEmpty) {
        continue;
      }
      final parts = line.split('\x1f');
      if (parts.length < 5) {
        continue;
      }
      commits.add(
        PrCommit(
          sha: parts[0].trim(),
          message: parts[1].trim(),
          author: null,
          date: DateTime.tryParse(parts[4].trim()),
        ),
      );
    }
    yield commits;
  }

  @override
  Stream<List<PrFile>> watchCommitFiles(
    PrSourceRequest req,
    String sha,
  ) async* {
    final manager = _buildManager(req);
    final clonePath = await manager.clonePath();

    if (!_isCloned(clonePath)) {
      yield const [];
      return;
    }

    final files = await _buildFileList(clonePath, '$sha^', sha);
    final result = await _git.run([
      'diff',
      '--no-color',
      '-M',
      '$sha^...$sha',
    ], workdir: clonePath);

    if (!result.isSuccess) {
      yield List<PrFile>.unmodifiable(files);
      return;
    }

    final patches = extractAllFilePatches(result.stdout);
    yield List<PrFile>.unmodifiable([
      for (final f in files)
        PrFile(
          filename: f.filename,
          status: f.status,
          additions: f.additions,
          deletions: f.deletions,
          patch: patches[f.filename] ?? '',
          previousFilename: f.previousFilename,
          viewerViewedState: f.viewerViewedState,
        ),
    ]);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  PrCloneManager _buildManager(PrSourceRequest req) {
    return PrCloneManager(
      git: _git,
      filesystem: _filesystem,
      workspaceId: req.workspaceId,
      owner: req.owner,
      repo: req.repo,
      githubToken: _githubToken,
      localCheckoutPath: req.localCheckoutPath,
      rift: _rift,
    );
  }

  bool _isCloned(String clonePath) => Directory('$clonePath/.git').existsSync();

  Future<String?> _resolveMergeBase(
    String clonePath,
    String baseRef,
    int prNumber,
  ) async {
    final headRef = 'refs/pr/$prNumber/head';
    final result = await _git.run([
      'merge-base',
      'origin/$baseRef',
      headRef,
    ], workdir: clonePath);
    if (result.isSuccess) {
      final sha = result.stdout.trim();
      if (sha.isNotEmpty) {
        return sha;
      }
    }
    // Fall back to origin/baseRef tip directly.
    final fallback = await _git.run([
      'rev-parse',
      'origin/$baseRef',
    ], workdir: clonePath);
    if (fallback.isSuccess) {
      final sha = fallback.stdout.trim();
      if (sha.isNotEmpty) {
        return sha;
      }
    }
    return null;
  }

  Future<List<PrFile>> _buildFileList(
    String clonePath,
    String base,
    String head, {
    void Function(String line)? onProgress,
  }) async {
    // Both commands use `-z`: NUL-delimited records with verbatim, unabbreviated
    // paths, and an explicit old/new pair for renames. WITHOUT -z, git compacts
    // a rename into a single `prefix{old => new}suffix` path that matches
    // neither the name-status full paths nor the patch headers — so a rename
    // renders as a "modified" file with a mangled path and no content.
    //
    // `git diff --numstat -z` gives additions/deletions per file. On a blobless
    // clone this is where git lazily fetches the changed blobs — forward its
    // progress so the UI shows the download instead of a frozen spinner.
    final numstatResult = await _git.run(
      ['diff', '--numstat', '-z', '-M', '$base...$head'],
      workdir: clonePath,
      onProgress: onProgress,
    );

    // `git diff --name-status -z` gives the file operation type and rename pairs.
    final nameStatusResult = await _git.run(
      ['diff', '--name-status', '-z', '-M', '$base...$head'],
      workdir: clonePath,
      onProgress: onProgress,
    );

    final statusMap = parseGitNameStatusZ(nameStatusResult.stdout);
    return parseGitNumstatZ(numstatResult.stdout, statusMap);
  }

  static ClonePhase _mapPhase(PrClonePhase p) {
    switch (p) {
      case PrClonePhase.cloning:
        return ClonePhase.cloning;
      case PrClonePhase.fetching:
        return ClonePhase.fetching;
      case PrClonePhase.computing:
        return ClonePhase.computing;
      case PrClonePhase.ready:
        return ClonePhase.ready;
      case PrClonePhase.error:
        return ClonePhase.error;
    }
  }
}
