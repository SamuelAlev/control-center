import 'dart:io';

import 'package:cc_domain/core/domain/ports/session_diff_port.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_infra/src/git/git_diff_z_parser.dart';
import 'package:cc_infra/src/git/working_tree_capture.dart';

/// A [SessionDiffPort] that shells out to `git` to compute what changed in a
/// worktree since a snapshot ref.
///
/// Mirrors the local-git PR diff source: `--name-status -z` for status/rename
/// info, `--numstat -z` for +/- counts, then a full `git diff` whose output is
/// sliced per-file by `extractAllFilePatches`. When `headRef` is omitted the
/// base ref is diffed against the live working tree, which is what "review what
/// this session changed before I commit" wants.
class ProcessSessionDiffAdapter implements SessionDiffPort {
  /// Creates a [ProcessSessionDiffAdapter].
  const ProcessSessionDiffAdapter();

  @override
  Future<List<PrFile>> changedFiles(
    String worktreePath,
    String baseRef, {
    String? headRef,
  }) async {
    if (!await _isWorktree(worktreePath)) {
      return const [];
    }
    // Diff two trees so brand-new (untracked) files show up — a plain
    // `git diff <tree>` ignores untracked files. When no head ref is given we
    // snapshot the working tree and diff against that.
    final head = headRef ?? await captureWorkingTree(worktreePath);
    if (head == null) {
      return const [];
    }
    final range = [baseRef, head];

    final nameStatus = await _run([
      'diff',
      '--name-status',
      '-z',
      ...range,
    ], worktreePath);
    final numstat = await _run([
      'diff',
      '--numstat',
      '-z',
      ...range,
    ], worktreePath);
    if (nameStatus.exitCode != 0 || numstat.exitCode != 0) {
      return const [];
    }
    final statusMap = parseGitNameStatusZ(nameStatus.stdout);
    final files = parseGitNumstatZ(numstat.stdout, statusMap);
    if (files.isEmpty) {
      return const [];
    }

    final full = await _run([
      '-c',
      'core.quotePath=false',
      'diff',
      '--no-color',
      ...range,
    ], worktreePath);
    if (full.exitCode != 0) {
      return files;
    }
    final patches = extractAllFilePatches(full.stdout);
    return [
      for (final f in files)
        PrFile(
          filename: f.filename,
          status: f.status,
          additions: f.additions,
          deletions: f.deletions,
          patch: patches[f.filename] ?? '',
          previousFilename: f.previousFilename,
        ),
    ];
  }

  @override
  Future<({List<PrFile> staged, List<PrFile> unstaged})> groupedChanges(
    String worktreePath,
  ) async {
    if (!await _isWorktree(worktreePath)) {
      return (staged: const <PrFile>[], unstaged: const <PrFile>[]);
    }
    // Sync the index's stat cache so a CoW copy's fresh mtimes don't make
    // unchanged files read as modified (git then content-compares and finds
    // them equal). Best-effort.
    await _run(['update-index', '-q', '--refresh'], worktreePath);

    // Staged = index vs HEAD; unstaged (tracked) = working tree vs index.
    final staged = await _filesForDiff(worktreePath, const [
      '--cached',
      'HEAD',
    ]);
    final unstagedTracked = await _filesForDiff(worktreePath, const []);
    final untracked = await _untrackedFiles(worktreePath);
    return (staged: staged, unstaged: [...unstagedTracked, ...untracked]);
  }

  /// Runs the name-status / numstat / full-diff triple for the given `git diff`
  /// [diffArgs] and assembles [PrFile]s (status + counts + patch).
  Future<List<PrFile>> _filesForDiff(
    String worktreePath,
    List<String> diffArgs,
  ) async {
    final nameStatus = await _run([
      'diff',
      '--name-status',
      '-z',
      ...diffArgs,
    ], worktreePath);
    final numstat = await _run([
      'diff',
      '--numstat',
      '-z',
      ...diffArgs,
    ], worktreePath);
    if (nameStatus.exitCode != 0 || numstat.exitCode != 0) {
      return const [];
    }
    final statusMap = parseGitNameStatusZ(nameStatus.stdout);
    final files = parseGitNumstatZ(numstat.stdout, statusMap);
    if (files.isEmpty) {
      return const [];
    }
    // quotePath=false keeps non-ASCII paths raw in the `diff --git` headers so
    // they match the verbatim `-z` paths — otherwise the per-file patch lookup
    // misses and the file renders with an empty body.
    final full = await _run([
      '-c',
      'core.quotePath=false',
      'diff',
      '--no-color',
      ...diffArgs,
    ], worktreePath);
    final patches = full.exitCode == 0
        ? extractAllFilePatches(full.stdout)
        : const <String, String>{};
    return [
      for (final f in files)
        PrFile(
          filename: f.filename,
          status: f.status,
          additions: f.additions,
          deletions: f.deletions,
          patch: patches[f.filename] ?? '',
          previousFilename: f.previousFilename,
        ),
    ];
  }

  /// Untracked files (not in the index), each as an added [PrFile] with a
  /// whole-file patch (via `git diff --no-index` against `/dev/null`).
  Future<List<PrFile>> _untrackedFiles(String worktreePath) async {
    final res = await _run([
      'ls-files',
      '--others',
      '--exclude-standard',
      '-z',
    ], worktreePath);
    if (res.exitCode != 0) {
      return const [];
    }
    final names = res.stdout.split('\x00').where((s) => s.isNotEmpty);
    final out = <PrFile>[];
    for (final name in names) {
      // --no-index exits 1 when the files differ (always, for a new file) — that
      // is expected, so read stdout regardless of the exit code.
      final diff = await _run([
        '-c',
        'core.quotePath=false',
        'diff',
        '--no-color',
        '--no-index',
        '--',
        '/dev/null',
        name,
      ], worktreePath);
      final patch = extractAllFilePatches(diff.stdout)[name] ?? diff.stdout;
      // Count added lines from the patch (lines starting with '+' that aren't
      // the '+++' file header).
      final additions = patch
          .split('\n')
          .where((l) => l.startsWith('+') && !l.startsWith('+++'))
          .length;
      out.add(
        PrFile(
          filename: name,
          status: PrFileStatus.added,
          additions: additions,
          deletions: 0,
          patch: patch,
        ),
      );
    }
    return out;
  }

  Future<bool> _isWorktree(String path) async {
    if (!Directory(path).existsSync()) {
      return false;
    }
    final result = await _run(['rev-parse', '--is-inside-work-tree'], path);
    return result.exitCode == 0 && result.stdout.trim() == 'true';
  }

  Future<({int exitCode, String stdout, String stderr})> _run(
    List<String> args,
    String workdir, {
    Map<String, String>? env,
  }) async {
    final result = await Process.run(
      'git',
      args,
      workingDirectory: workdir,
      environment: env,
    );
    return (
      exitCode: result.exitCode,
      stdout: result.stdout as String,
      stderr: result.stderr as String,
    );
  }
}
