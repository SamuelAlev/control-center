import 'dart:io';

import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_domain/features/dispatch/domain/isolation/worktree_isolation.dart';
import 'package:path/path.dart' as p;

/// Git-backed `WorktreeIsolationRunner`.
///
/// Each isolated spawn runs in a throwaway `git worktree` checked out at the
/// captured baseline, so parallel writers never collide on the parent working
/// tree. On success the changes are captured as a `cc/task/<id>` branch (branch
/// mode) or a `<id>.patch` artifact (patch mode); the worktree is always
/// removed in a `finally`. Merge-back is a cherry-pick (branch) or `git apply`
/// (patch); a branch-mode conflict preserves the branch for manual resolution.
class GitWorktreeIsolationRunner implements WorktreeIsolationRunner {
  /// Creates a runner backed by the given git command port. [worktreeRoot] is
  /// where throwaway worktrees are created (defaults to the system temp dir).
  ///
  /// [authorName] / [authorEmail] set the commit identity stamped on capture
  /// commits, so isolated task commits attribute to the acting agent rather
  /// than a generic product identity; the defaults preserve the previous
  /// behaviour. [coAuthoredBy] is an optional `Name <email>` credit for the
  /// requesting human, appended to capture-commit messages as a
  /// `Co-Authored-By:` trailer.
  GitWorktreeIsolationRunner(
    this._git, {
    String? worktreeRoot,
    String? authorName,
    String? authorEmail,
    String? coAuthoredBy,
  }) : _worktreeRoot = worktreeRoot ?? Directory.systemTemp.path,
       _coAuthoredBy = coAuthoredBy,
       _commitIdentity = [
         '-c',
         'user.name=${authorName ?? 'Control Center'}',
         '-c',
         'user.email=${authorEmail ?? 'control-center@local'}',
       ];

  final GitCommandPort _git;
  final String _worktreeRoot;

  /// The `Name <email>` credited as co-author on capture commits, or null.
  final String? _coAuthoredBy;

  static const String _branchPrefix = 'cc/task/';
  final List<String> _commitIdentity;

  @override
  Future<IsolationContext> prepareContext(String cwd) async {
    final root = await _git.run(['rev-parse', '--show-toplevel'], workdir: cwd);
    if (!root.isSuccess) {
      throw StateError('Not a git repository: $cwd (${root.stderr.trim()})');
    }
    final repoRoot = root.stdout.trim();
    final head = await _git.run(['rev-parse', 'HEAD'], workdir: repoRoot);
    if (!head.isSuccess) {
      throw StateError(
        'Could not resolve HEAD in $repoRoot (${head.stderr.trim()})',
      );
    }
    return IsolationContext(
      repoRoot: repoRoot,
      baseline: WorktreeBaseline(
        repoRoot: repoRoot,
        headSha: head.stdout.trim(),
      ),
    );
  }

  @override
  Future<IsolatedRunResult> runIsolated({
    required IsolationContext context,
    required String agentId,
    required IsolationMergeMode mergeMode,
    required String artifactsDir,
    required Future<int> Function(String worktreeDir) run,
    String? description,
  }) async {
    final repoRoot = context.repoRoot;
    final worktreeDir = p.join(_worktreeRoot, 'cc-iso-$agentId-${_stamp()}');
    var added = false;
    try {
      final add = await _git.run([
        'worktree',
        'add',
        '--detach',
        worktreeDir,
        context.baseline.headSha,
      ], workdir: repoRoot);
      if (!add.isSuccess) {
        return IsolatedRunResult(
          agentId: agentId,
          exitCode: 1,
          error: 'Failed to create isolation worktree: ${add.stderr.trim()}',
          description: description,
        );
      }
      added = true;

      final exitCode = await run(worktreeDir);
      if (exitCode != 0) {
        return IsolatedRunResult(
          agentId: agentId,
          exitCode: exitCode,
          description: description,
        );
      }

      // Stage everything (including untracked) so both capture modes see the
      // full delta.
      final staged = await _git.run(['add', '-A'], workdir: worktreeDir);
      if (!staged.isSuccess) {
        return IsolatedRunResult(
          agentId: agentId,
          exitCode: 0,
          error: 'Failed to stage changes: ${staged.stderr.trim()}',
          description: description,
        );
      }
      if (!await _hasStagedChanges(worktreeDir)) {
        // Clean run — nothing to capture.
        return IsolatedRunResult(
          agentId: agentId,
          exitCode: 0,
          description: description,
        );
      }

      if (mergeMode == IsolationMergeMode.branch) {
        return await _captureBranch(
          worktreeDir: worktreeDir,
          agentId: agentId,
          description: description,
        );
      }
      return await _capturePatch(
        worktreeDir: worktreeDir,
        agentId: agentId,
        artifactsDir: artifactsDir,
        description: description,
      );
    } finally {
      if (added) {
        await _git.run([
          'worktree',
          'remove',
          '--force',
          worktreeDir,
        ], workdir: repoRoot);
        await _git.run(['worktree', 'prune'], workdir: repoRoot);
      }
    }
  }

  @override
  Future<IsolationMergeOutcome> mergeChanges({
    required IsolatedRunResult result,
    required String repoRoot,
    required IsolationMergeMode mergeMode,
  }) async {
    if (!result.succeeded) {
      return const IsolationMergeOutcome(
        summary: '\n\nNo changes to apply.',
        changesApplied: true,
        hadChanges: false,
      );
    }
    if (mergeMode == IsolationMergeMode.branch) {
      return _mergeBranch(result, repoRoot);
    }
    return _applyPatch(result, repoRoot);
  }

  Future<IsolatedRunResult> _captureBranch({
    required String worktreeDir,
    required String agentId,
    String? description,
  }) async {
    final subject = description == null || description.trim().isEmpty
        ? 'cc(task): $agentId'
        : 'cc(task): $description';
    // Credit the requesting human alongside the committing agent identity.
    final message = _coAuthoredBy == null || _coAuthoredBy.trim().isEmpty
        ? subject
        : '$subject\n\nCo-Authored-By: ${_coAuthoredBy.trim()}';
    final commit = await _git.run([
      ..._commitIdentity,
      'commit',
      '-m',
      message,
    ], workdir: worktreeDir);
    if (!commit.isSuccess) {
      return IsolatedRunResult(
        agentId: agentId,
        exitCode: 0,
        error: 'Commit failed: ${commit.stderr.trim()}',
        description: description,
      );
    }
    final branchName = '$_branchPrefix$agentId';
    final branch = await _git.run([
      'branch',
      '-f',
      branchName,
      'HEAD',
    ], workdir: worktreeDir);
    if (!branch.isSuccess) {
      return IsolatedRunResult(
        agentId: agentId,
        exitCode: 0,
        error: 'Branch capture failed: ${branch.stderr.trim()}',
        description: description,
      );
    }
    return IsolatedRunResult(
      agentId: agentId,
      exitCode: 0,
      branchName: branchName,
      description: description,
    );
  }

  Future<IsolatedRunResult> _capturePatch({
    required String worktreeDir,
    required String agentId,
    required String artifactsDir,
    String? description,
  }) async {
    final diff = await _git.run([
      'diff',
      '--cached',
      '--binary',
    ], workdir: worktreeDir);
    if (!diff.isSuccess) {
      return IsolatedRunResult(
        agentId: agentId,
        exitCode: 0,
        error: 'Patch capture failed: ${diff.stderr.trim()}',
        description: description,
      );
    }
    await Directory(artifactsDir).create(recursive: true);
    final patchPath = p.join(artifactsDir, '$agentId.patch');
    final text = diff.stdout.endsWith('\n') ? diff.stdout : '${diff.stdout}\n';
    await File(patchPath).writeAsString(text);
    return IsolatedRunResult(
      agentId: agentId,
      exitCode: 0,
      patchPath: patchPath,
      description: description,
    );
  }

  Future<IsolationMergeOutcome> _mergeBranch(
    IsolatedRunResult result,
    String repoRoot,
  ) async {
    final branchName = result.branchName;
    if (branchName == null) {
      return const IsolationMergeOutcome(
        summary: '\n\nNo changes to apply.',
        changesApplied: true,
        hadChanges: false,
      );
    }
    final tip = await _git.run(['rev-parse', branchName], workdir: repoRoot);
    if (!tip.isSuccess) {
      return IsolationMergeOutcome(
        summary: '\n\nBranch $branchName not found; nothing applied.',
        changesApplied: false,
        hadChanges: false,
      );
    }
    final pick = await _git.run([
      ..._commitIdentity,
      'cherry-pick',
      '--no-edit',
      tip.stdout.trim(),
    ], workdir: repoRoot);
    if (pick.isSuccess) {
      // Merged cleanly — drop the now-redundant branch.
      await _git.run(['branch', '-D', branchName], workdir: repoRoot);
      return IsolationMergeOutcome(
        summary: '\n\nMerged branch: $branchName',
        changesApplied: true,
        hadChanges: true,
      );
    }
    // Conflict: abort the cherry-pick and preserve the branch for manual fix.
    await _git.run(['cherry-pick', '--abort'], workdir: repoRoot);
    return IsolationMergeOutcome(
      summary:
          '\n\nBranch merge failed: $branchName. '
          'The unmerged branch remains for manual resolution.',
      changesApplied: false,
      hadChanges: false,
    );
  }

  Future<IsolationMergeOutcome> _applyPatch(
    IsolatedRunResult result,
    String repoRoot,
  ) async {
    final patchPath = result.patchPath;
    if (patchPath == null) {
      return const IsolationMergeOutcome(
        summary: '\n\nNo changes to apply.',
        changesApplied: true,
        hadChanges: false,
      );
    }
    final text = await File(patchPath).readAsString();
    if (text.trim().isEmpty) {
      return const IsolationMergeOutcome(
        summary: '\n\nNo changes to apply.',
        changesApplied: true,
        hadChanges: false,
      );
    }
    final check = await _git.run([
      'apply',
      '--check',
      patchPath,
    ], workdir: repoRoot);
    if (!check.isSuccess) {
      return IsolationMergeOutcome(
        summary:
            '\n\nPatches were not applied and must be handled manually.'
            '\n\nPatch artifact:\n- $patchPath',
        changesApplied: false,
        hadChanges: false,
      );
    }
    final apply = await _git.run(['apply', patchPath], workdir: repoRoot);
    if (!apply.isSuccess) {
      return IsolationMergeOutcome(
        summary:
            '\n\nPatches were not applied and must be handled manually.'
            '\n\nPatch artifact:\n- $patchPath',
        changesApplied: false,
        hadChanges: false,
      );
    }
    return const IsolationMergeOutcome(
      summary: '\n\nApplied patches: yes',
      changesApplied: true,
      hadChanges: true,
    );
  }

  Future<bool> _hasStagedChanges(String worktreeDir) async {
    final status = await _git.run([
      'status',
      '--porcelain',
    ], workdir: worktreeDir);
    return status.stdout.trim().isNotEmpty;
  }

  int _counter = 0;
  String _stamp() => '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
}
