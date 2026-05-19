import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/core/domain/ports/git_command_port.dart';
import 'package:control_center/core/domain/ports/repo_isolation_port.dart';
import 'package:control_center/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:path/path.dart' as p;

/// [RepoIsolationPort] backed by the bundled rift CoW library, with a plain
/// `git worktree` fallback.
///
/// Token handling for fetch mirrors `PrCloneManager`: the auth URL is only ever
/// a transient positional argument with credential helpers disabled, never
/// written to `.git/config`.
class RiftRepoIsolationAdapter implements RepoIsolationPort {
  /// Creates a [RiftRepoIsolationAdapter].
  RiftRepoIsolationAdapter({required RiftClient rift, required GitCommandPort git})
      : _rift = rift,
        _git = git;

  final RiftClient _rift;
  final GitCommandPort _git;

  static const _tag = 'RiftRepoIsolation';

  @override
  bool get isCowAvailable => _rift.isAvailable;

  Map<String, String> get _baseEnv => const {
        'GIT_TERMINAL_PROMPT': '0',
        'GIT_ASKPASS': 'echo',
        'GIT_CONFIG_NOSYSTEM': '1',
      };

  List<String> get _noCred => const ['-c', 'credential.helper='];

  @override
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    String baseRef = '',
    String? authUrl,
    String? headRef,
  }) async {
    await Directory(destParentDir).create(recursive: true);
    // The base is only needed when branching off it; the [headRef] path checks
    // out fetched commits directly, so skip the read-only default-branch probe.
    final resolvedBase = (headRef != null && headRef.isNotEmpty)
        ? baseRef
        : (baseRef.isNotEmpty
            ? baseRef
            : await _resolveDefaultBranch(sourcePath));

    if (_rift.isAvailable) {
      try {
        final copyPath = await _riftCreate(sourcePath, destParentDir, name);
        await _fetchAndBranch(
          worktree: copyPath,
          branch: branch,
          baseRef: resolvedBase,
          authUrl: authUrl,
          headRef: headRef,
        );
        return RepoIsolationResult(
          path: copyPath,
          backend: RepoIsolationBackend.rift,
        );
      } on RiftException catch (e) {
        if (e.isUnsafeGit) {
          // Source is mid-merge/rebase or locked — a worktree would fail too.
          rethrow;
        }
        if (!e.isCowUnavailable) {
          AppLog.w(_tag, 'rift create failed (${e.code}); '
              'falling back to git worktree: ${e.message}');
        } else {
          AppLog.w(_tag, 'CoW unavailable; falling back to git worktree on '
              'source .git for $sourcePath');
        }
        // fall through to worktree fallback
      }
    }

    return _worktreeFallback(
      sourcePath: sourcePath,
      destParentDir: destParentDir,
      name: name,
      branch: branch,
      baseRef: resolvedBase,
      authUrl: authUrl,
      headRef: headRef,
    );
  }

  /// Runs `rift init` (idempotent) then `rift create`, retrying once if the
  /// source turns out not to be registered yet.
  Future<String> _riftCreate(
    String sourcePath,
    String destParentDir,
    String name,
  ) async {
    try {
      await _rift.init(at: sourcePath);
    } on RiftException catch (e) {
      // init is idempotent; only a hard failure (e.g. unsafe git) should stop us
      if (e.isUnsafeGit) {
        rethrow;
      }
      AppLog.d(_tag, 'rift init note (${e.code}): ${e.message}');
    }
    try {
      return await _rift.create(
        from: sourcePath,
        into: destParentDir,
        name: name,
        copyAll: true,
        hooks: false,
      );
    } on RiftException catch (e) {
      if (e.isInitRequired) {
        await _rift.init(at: sourcePath);
        return _rift.create(
          from: sourcePath,
          into: destParentDir,
          name: name,
          copyAll: true,
          hooks: false,
        );
      }
      rethrow;
    }
  }

  Future<void> _fetchAndBranch({
    required String worktree,
    required String branch,
    required String baseRef,
    required String? authUrl,
    String? headRef,
  }) async {
    // PR / explicit-ref path: fetch the requested ref to FETCH_HEAD, then point
    // [branch] at exactly that commit and check it out — so the copy lands on
    // the fetched commits (e.g. a PR head), never a fresh branch off the base.
    if (headRef != null && headRef.isNotEmpty) {
      if (authUrl == null) {
        throw StateError('Cannot check out $headRef without an auth URL');
      }
      final fetch = await _git.run(
        [..._noCred, 'fetch', '--no-tags', '--force', authUrl, headRef],
        workdir: worktree,
        env: _baseEnv,
      );
      if (!fetch.isSuccess) {
        throw StateError('Failed to fetch $headRef: ${fetch.stderr.trim()}');
      }
      // `-B` (re)creates [branch] at FETCH_HEAD even if it already exists or is
      // the current branch, guaranteeing the working tree matches the PR head.
      final checkout = await _git.run(
        [..._noCred, 'checkout', '--force', '-B', branch, 'FETCH_HEAD'],
        workdir: worktree,
        env: _baseEnv,
      );
      if (!checkout.isSuccess) {
        throw StateError(
          'Failed to check out $headRef in $worktree: ${checkout.stderr.trim()}',
        );
      }
      return;
    }

    var hasOriginBase = false;
    if (authUrl != null) {
      final fetch = await _git.run(
        [
          ..._noCred,
          'fetch',
          '--no-tags',
          '--force',
          authUrl,
          '$baseRef:refs/remotes/origin/$baseRef',
        ],
        workdir: worktree,
        env: _baseEnv,
      );
      hasOriginBase = fetch.isSuccess;
      if (!fetch.isSuccess) {
        AppLog.w(_tag, 'fetch of $baseRef failed; branching off local state: '
            '${fetch.stderr.trim()}');
      }
    }

    // Prefer the freshly-fetched remote base; degrade to the local branch, then
    // to the copy's current (detached) HEAD.
    final startPoints = [
      if (hasOriginBase) 'refs/remotes/origin/$baseRef',
      baseRef,
    ];
    for (final start in startPoints) {
      final res = await _git.run(
        [..._noCred, 'checkout', '-b', branch, start],
        workdir: worktree,
        env: _baseEnv,
      );
      if (res.isSuccess) {
        return;
      }
    }
    // Last resort: branch off whatever HEAD points at in the copy.
    final fallback = await _git.run(
      [..._noCred, 'checkout', '-b', branch],
      workdir: worktree,
      env: _baseEnv,
    );
    if (!fallback.isSuccess) {
      throw StateError(
        'Failed to create branch $branch in $worktree: ${fallback.stderr.trim()}',
      );
    }
  }

  Future<RepoIsolationResult> _worktreeFallback({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    required String baseRef,
    required String? authUrl,
    String? headRef,
  }) async {
    final destPath = p.join(destParentDir, name);

    // PR / explicit-ref path: fetch the ref to the source's FETCH_HEAD (this
    // touches the source .git — accepted on the fallback path), then add a
    // worktree with [branch] (re)created at exactly that commit.
    if (headRef != null && headRef.isNotEmpty) {
      if (authUrl == null) {
        throw StateError('Cannot check out $headRef without an auth URL');
      }
      final fetch = await _git.run(
        [..._noCred, 'fetch', '--no-tags', '--force', authUrl, headRef],
        workdir: sourcePath,
        env: _baseEnv,
      );
      if (!fetch.isSuccess) {
        throw StateError(
          'worktree-fallback PR fetch failed: ${fetch.stderr.trim()}',
        );
      }
      // Check out detached at the fetched commit rather than creating a branch
      // named after the PR head-ref in the SOURCE repo's shared branch
      // namespace — that could reset/delete the user's same-named local branch
      // on teardown. (The rift path keeps a real branch; it's an isolated copy.)
      final add = await _git.run(
        ['worktree', 'add', '--force', '--detach', destPath, 'FETCH_HEAD'],
        workdir: sourcePath,
        env: _baseEnv,
      );
      if (!add.isSuccess) {
        throw StateError(
          'git worktree add failed for $destPath: ${add.stderr.trim()}',
        );
      }
      AppLog.w(_tag, 'Provisioned PR worktree via git worktree '
          '(touched source .git): $destPath on $branch');
      return RepoIsolationResult(
        path: destPath,
        backend: RepoIsolationBackend.gitWorktree,
      );
    }

    // Refresh the source's remote-tracking base first (this DOES touch the
    // source .git — accepted only on the fallback path).
    if (authUrl != null) {
      final fetch = await _git.run(
        [
          ..._noCred,
          'fetch',
          '--no-tags',
          '--force',
          authUrl,
          '$baseRef:refs/remotes/origin/$baseRef',
        ],
        workdir: sourcePath,
        env: _baseEnv,
      );
      if (!fetch.isSuccess) {
        AppLog.w(_tag, 'worktree-fallback fetch failed: ${fetch.stderr.trim()}');
      }
    }

    final startPoints = ['refs/remotes/origin/$baseRef', baseRef, 'HEAD'];
    for (final start in startPoints) {
      final res = await _git.run(
        ['worktree', 'add', '-b', branch, destPath, start],
        workdir: sourcePath,
        env: _baseEnv,
      );
      if (res.isSuccess) {
        AppLog.w(_tag, 'Provisioned via git worktree (touched source .git): '
            '$destPath on $branch');
        return RepoIsolationResult(
          path: destPath,
          backend: RepoIsolationBackend.gitWorktree,
        );
      }
    }
    throw StateError('git worktree add failed for $destPath');
  }

  /// Reads the source repo's default branch without mutating it.
  Future<String> _resolveDefaultBranch(String sourcePath) async {
    final originHead = await _git.run(
      ['symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
      workdir: sourcePath,
    );
    if (originHead.isSuccess) {
      final ref = originHead.stdout.trim();
      final slash = ref.lastIndexOf('/');
      final name = slash >= 0 ? ref.substring(slash + 1) : ref;
      if (name.isNotEmpty) {
        return name;
      }
    }
    final head = await _git.run(
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workdir: sourcePath,
    );
    final headName = head.stdout.trim();
    if (head.isSuccess && headName.isNotEmpty && headName != 'HEAD') {
      return headName;
    }
    return 'main';
  }

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async {
    switch (backend) {
      case RepoIsolationBackend.rift:
        try {
          await _rift.remove(at: path);
        } on RiftException catch (e) {
          if (!e.isMissing) {
            AppLog.w(_tag, 'rift remove failed (${e.code}): ${e.message}');
          }
        }
        try {
          await _rift.gc();
        } on RiftException catch (e) {
          AppLog.d(_tag, 'rift gc note: ${e.message}');
        }
        // Belt-and-suspenders: drop the directory if rift left it behind.
        final dir = Directory(path);
        if (dir.existsSync()) {
          try {
            await dir.delete(recursive: true);
          } catch (_) {}
        }
      case RepoIsolationBackend.gitWorktree:
        final remove = await _git.run(
          ['worktree', 'remove', '--force', path],
          workdir: sourcePath,
        );
        if (!remove.isSuccess) {
          AppLog.w(_tag, 'worktree remove failed: ${remove.stderr.trim()}');
        }
        if (branch != null && branch.isNotEmpty) {
          await _git.run(['branch', '-D', branch], workdir: sourcePath);
        }
    }
  }
}
