import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;

/// [RepoIsolationPort] backed by the bundled rift CoW library, with a plain
/// `git worktree` path for the two cases where CoW genuinely cannot be used.
///
/// **`git worktree` is a backend, not a degraded mode.** It is reached only when:
///   * the filesystem cannot do copy-on-write (`cow_unavailable` — non-APFS /
///     non-reflink, or source and destination on different volumes). Environment,
///     not install: the fallback is correct and permanent.
///   * rift is not built for the platform (`missingRiftIsExpected`, i.e.
///     Windows — there is no MSVC CoW backend).
///   * a persisted worktree row from either of the above is being torn down.
///
/// Everything else that rift can report about the SOURCE is repaired in place
/// rather than fallen back on. In particular a `.rift` marker this registry does
/// not recognise (left by another registry file, or surviving a data-dir reset)
/// is cleared and re-adopted: the marker lives in the user's repo and never
/// expires, so degrading on it would pin that repo to `git worktree` forever.
///
/// A missing `librift_ffi` on a platform that ships it is a BROKEN INSTALL and
/// propagates as `RiftException(code: 'unavailable')`; `cc_server` refuses to
/// boot on it in the first place (see its native preflight). It must never fall
/// back, because a silent `git worktree` provision would hide the broken native
/// behind a slower-but-working path indefinitely.
///
/// Token handling for fetch mirrors `PrCloneManager`: the auth URL is only ever
/// a transient positional argument with credential helpers disabled, never
/// written to `.git/config`.
class RiftRepoIsolationAdapter implements RepoIsolationPort {
  /// Creates a [RiftRepoIsolationAdapter].
  ///
  /// [missingRiftIsExpected] defaults to `Platform.isWindows`, the one platform
  /// that deliberately ships no rift (`scripts/release/windows_natives.sh`
  /// documents why: no MSVC CoW backend). Injectable so both branches are
  /// testable from any host.
  RiftRepoIsolationAdapter({
    required RiftClient rift,
    required GitCommandPort git,
    bool? missingRiftIsExpected,
  }) : _rift = rift,
       _git = git,
       _missingRiftIsExpected = missingRiftIsExpected ?? Platform.isWindows;

  final RiftClient _rift;
  final GitCommandPort _git;

  /// Whether an unloadable `librift_ffi` is a supported platform gap (Windows)
  /// rather than a broken install.
  final bool _missingRiftIsExpected;

  @override
  bool get isCowAvailable => _rift.isAvailable;

  /// The error raised when the rift native is missing on a platform that ships
  /// it. Deliberately the same `code` the client/worker synthesise, so every
  /// caller can branch on `RiftException.isUnavailable`.
  static const _unavailable = RiftException(
    code: 'unavailable',
    message:
        'rift native library is not loaded — build it with '
        'scripts/natives/build_rift.sh, or rebuild the host bundle with the '
        'natives staged. CoW worktrees are required on this platform; there is '
        'no git-worktree fallback for a missing dylib.',
  );

  Map<String, String> get _baseEnv => const {
    'GIT_TERMINAL_PROMPT': '0',
    'GIT_ASKPASS': 'echo',
    'GIT_CONFIG_NOSYSTEM': '1',
  };

  List<String> get _noCred => const ['-c', 'credential.helper='];

  /// Fetch argv prefix: no credential helpers, no prune (a user
  /// `fetch.prune` in `~/.gitconfig` must not delete `origin/main` as a
  /// side effect of writing FETCH_HEAD).
  List<String> get _fetchCmd => [
    ..._noCred,
    '-c',
    'fetch.prune=false',
    'fetch',
    '--no-tags',
    '--force',
  ];

  /// Splits an `authUrl` of the form `https://x-access-token:TOKEN@github.com/…`
  /// into the CLEAN url + an auth env so the token rides in
  /// `GIT_CONFIG_PARAMETERS` (env, not argv, so invisible to `ps`) and git
  /// sends it as an Authorization header (never echoed on stderr). Token-less
  /// / non-GitHub URLs pass through with the base env (VULN-010).
  ({String url, Map<String, String> env}) _resolveAuth(String? authUrl) {
    if (authUrl == null || authUrl.isEmpty) {
      return (url: '', env: _baseEnv);
    }
    final uri = Uri.tryParse(authUrl);
    final userInfo = uri?.userInfo ?? '';
    if (uri == null || uri.host != 'github.com' || !userInfo.contains(':')) {
      return (url: authUrl, env: _baseEnv);
    }
    final token = userInfo.split(':').skip(1).join(':');
    if (token.isEmpty) {
      return (url: authUrl, env: _baseEnv);
    }
    final clean = uri.replace(userInfo: '').toString();
    final b64 = base64Encode(utf8.encode('x-access-token:$token'));
    final param =
        "'http.https://github.com/.extraHeader=Authorization: Basic $b64'";
    return (url: clean, env: {..._baseEnv, 'GIT_CONFIG_PARAMETERS': param});
  }

  @override
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    String baseRef = '',
    String? authUrl,
    String? headRef,
    bool pristine = false,
  }) async {
    await Directory(destParentDir).create(recursive: true);
    // The base is only needed when branching off it; the [headRef] path checks
    // out fetched commits directly, so skip the read-only default-branch probe.
    final resolvedBase = (headRef != null && headRef.isNotEmpty)
        ? baseRef
        : (baseRef.isNotEmpty
              ? baseRef
              : await _resolveDefaultBranch(sourcePath));
    final auth = _resolveAuth(authUrl);

    if (!_rift.isAvailable && !_missingRiftIsExpected) {
      // Broken install, not an environment gap — fail loudly rather than
      // provisioning a slower git worktree that hides it forever.
      throw _unavailable;
    }

    if (_rift.isAvailable) {
      try {
        final copyPath = await _riftCreate(sourcePath, destParentDir, name);
        await _fetchAndBranch(
          worktree: copyPath,
          branch: branch,
          baseRef: resolvedBase,
          authUrl: auth.url,
          authEnv: auth.env,
          headRef: headRef,
        );
        if (pristine) {
          await _scrubToHead(copyPath);
        }
        return RepoIsolationResult(
          path: copyPath,
          backend: RepoIsolationBackend.rift,
        );
      } on RiftException catch (e) {
        if (e.isUnsafeGit) {
          // Source is mid-merge/rebase or locked — a worktree would fail too.
          rethrow;
        }
        if (e.isUnavailable && !_missingRiftIsExpected) {
          // The main-isolate probe passed but the worker isolate could not load
          // the dylib: a broken install (partial bundle, wrong arch), so it must
          // surface rather than silently switch backends.
          rethrow;
        }
        if (!e.isCowUnavailable) {
          // An operational rift failure (protocol hiccup, registry contention).
          // Not a missing native — a worktree still yields a correct result.
          CcInfraLog.warning(
            'rift create failed (${e.code}); '
            'falling back to git worktree: ${e.message}',
          );
        } else {
          CcInfraLog.warning(
            'CoW unavailable; falling back to git worktree on '
            'source .git for $sourcePath',
          );
        }
        // fall through to the worktree backend
      }
    }

    return _worktreeFallback(
      sourcePath: sourcePath,
      destParentDir: destParentDir,
      name: name,
      branch: branch,
      baseRef: resolvedBase,
      authUrl: auth.url,
      authEnv: auth.env,
      headRef: headRef,
      pristine: pristine,
    );
  }

  /// Scrubs the worktree to exactly its checked-out tree: removes untracked and
  /// ignored files (`git clean -ffdx`) that a `copyAll` CoW copy inherited from
  /// the source working dir. Best-effort — a clean failure must not fail the
  /// provision (the worst case is the prior behaviour: leftover cruft).
  Future<void> _scrubToHead(String worktree) async {
    final res = await _git.run(
      [..._noCred, 'clean', '-ffdx'],
      workdir: worktree,
      env: _baseEnv,
    );
    if (!res.isSuccess) {
      CcInfraLog.warning(
        'pristine clean failed for $worktree: ${res.stderr.trim()}',
      );
    }
  }

  /// Runs `rift init` (idempotent) then `rift create`, retrying once if the
  /// source turns out not to be registered yet or carries a marker this registry
  /// does not know.
  Future<String> _riftCreate(
    String sourcePath,
    String destParentDir,
    String name,
  ) async {
    await _initSource(sourcePath);
    try {
      return await _create(sourcePath, destParentDir, name);
    } on RiftException catch (e) {
      final retryable =
          e.isInitRequired ||
          (e.isStaleMarker && await _clearStaleMarker(sourcePath, e));
      if (!retryable) {
        rethrow;
      }
      await _rift.init(at: sourcePath);
      return _create(sourcePath, destParentDir, name);
    }
  }

  Future<String> _create(
    String sourcePath,
    String destParentDir,
    String name,
  ) => _rift.create(
    from: sourcePath,
    into: destParentDir,
    name: name,
    copyAll: true,
    hooks: false,
  );

  /// `rift init` on the source. Idempotent, so every outcome but an unsafe git
  /// state is tolerated — except a marker this registry does not recognise,
  /// which is cleared and re-initialised rather than left to strand the repo on
  /// the `git worktree` backend for good (see [RiftException.isStaleMarker]).
  Future<void> _initSource(String sourcePath) async {
    try {
      await _rift.init(at: sourcePath);
      return;
    } on RiftException catch (e) {
      if (e.isUnsafeGit) {
        rethrow;
      }
      if (!e.isStaleMarker || !await _clearStaleMarker(sourcePath, e)) {
        CcInfraLog.info('rift init note (${e.code}): ${e.message}');
        return;
      }
    }
    try {
      await _rift.init(at: sourcePath);
    } on RiftException catch (e) {
      if (e.isUnsafeGit) {
        rethrow;
      }
      CcInfraLog.info('rift init note (${e.code}): ${e.message}');
    }
  }

  /// Drops the unrecognised `.rift` marker so the source can be re-adopted.
  /// Returns whether the caller should retry. Best-effort: a marker we cannot
  /// delete (permissions, read-only checkout) leaves the caller on the previous
  /// behaviour — the `git worktree` backend — instead of failing the provision.
  Future<bool> _clearStaleMarker(String sourcePath, RiftException cause) async {
    try {
      final cleared = await _rift.clearMarker(at: sourcePath);
      if (!cleared) {
        return false;
      }
      CcInfraLog.warning(
        'rift marker at $sourcePath was unknown to this registry '
        '(${cause.code}); cleared it and re-adopting the source so worktrees '
        'stay copy-on-write',
      );
      return true;
    } on Object catch (e) {
      CcInfraLog.warning(
        'could not clear the stale rift marker at $sourcePath ($e); '
        'falling back to the git worktree backend',
      );
      return false;
    }
  }

  Future<void> _fetchAndBranch({
    required String worktree,
    required String branch,
    required String baseRef,
    required String? authUrl,
    required Map<String, String> authEnv,
    String? headRef,
  }) async {
    // PR / explicit-ref path: fetch the requested ref to FETCH_HEAD, then point
    // [branch] at exactly that commit and check it out — so the copy lands on
    // the fetched commits (e.g. a PR head), never a fresh branch off the base.
    if (headRef != null && headRef.isNotEmpty) {
      // `_resolveAuth` normalises a missing/empty auth URL to '' (never null),
      // so guard on emptiness too — fetching a PR head-ref needs a real remote
      // URL, and `git fetch '' <ref>` would silently target the wrong remote.
      if (authUrl == null || authUrl.isEmpty) {
        throw StateError('Cannot check out $headRef without an auth URL');
      }
      final fetch = await _git.run(
        [..._fetchCmd, authUrl, headRef],
        workdir: worktree,
        env: authEnv,
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

    final fetched = await _fetchToFetchHead(
      workdir: worktree,
      authUrl: authUrl,
      authEnv: authEnv,
      ref: baseRef,
    );

    // Prefer the freshly-fetched remote default branch; then the inherited
    // remote-tracking ref / local branch of the same name. Never start from
    // the copy's current HEAD unless those are all missing — that is often a
    // custom feature branch the source had checked out.
    final startPoints = [
      if (fetched) 'FETCH_HEAD',
      'refs/remotes/origin/$baseRef',
      if (baseRef.isNotEmpty) baseRef,
    ];
    for (final start in startPoints) {
      final res = await _git.run(
        [..._noCred, 'checkout', '--force', '-B', branch, start],
        workdir: worktree,
        env: _baseEnv,
      );
      if (res.isSuccess) {
        return;
      }
    }
    CcInfraLog.warning(
      'no default-branch start point for $branch in $worktree; '
      "branching off the copy's current HEAD",
    );
    final fallback = await _git.run(
      [..._noCred, 'checkout', '--force', '-B', branch],
      workdir: worktree,
      env: _baseEnv,
    );
    if (!fallback.isSuccess) {
      throw StateError(
        'Failed to create branch $branch in $worktree: ${fallback.stderr.trim()}',
      );
    }
  }

  /// Resolves a fetch URL that is not the named remote `origin` (fetching
  /// `origin` would update `refs/remotes/origin/*` and can lock/delete
  /// `origin/main`). Empty [authUrl] falls back to `git remote get-url origin`
  /// so the URL is still positional. Never returns `''`.
  Future<String?> _resolveFetchUrl(String? authUrl, String workdir) async {
    if (authUrl != null && authUrl.isNotEmpty) {
      return authUrl;
    }
    final remote = await _git.run([
      'remote',
      'get-url',
      'origin',
    ], workdir: workdir);
    if (!remote.isSuccess) {
      return null;
    }
    final url = remote.stdout.trim();
    return url.isEmpty ? null : url;
  }

  /// Fetches [ref] from a URL into FETCH_HEAD only (no dest refspec). Returns
  /// whether the fetch succeeded. A missing URL is a skip, not a failure.
  Future<bool> _fetchToFetchHead({
    required String workdir,
    required String? authUrl,
    required Map<String, String> authEnv,
    required String ref,
  }) async {
    if (ref.isEmpty) {
      return false;
    }
    final url = await _resolveFetchUrl(authUrl, workdir);
    if (url == null) {
      return false;
    }
    final fetch = await _git.run(
      [..._fetchCmd, url, ref],
      workdir: workdir,
      env: authEnv,
    );
    if (!fetch.isSuccess) {
      CcInfraLog.warning('fetch of $ref failed: ${fetch.stderr.trim()}');
    }
    return fetch.isSuccess;
  }

  /// The plain `git worktree` backend, used when CoW is genuinely unusable:
  /// a non-CoW filesystem, an operational rift error, or a platform that ships
  /// no rift (Windows). Never used to paper over a missing dylib — see the class
  /// doc.
  Future<RepoIsolationResult> _worktreeFallback({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    required String baseRef,
    required String? authUrl,
    required Map<String, String> authEnv,
    String? headRef,
    bool pristine = false,
  }) async {
    final destPath = p.join(destParentDir, name);

    // PR / explicit-ref path: fetch the ref to the source's FETCH_HEAD (this
    // touches the source .git — accepted on the fallback path), then add a
    // worktree with [branch] (re)created at exactly that commit.
    if (headRef != null && headRef.isNotEmpty) {
      // `_resolveAuth` normalises a missing/empty auth URL to '' (never null),
      // so guard on emptiness too — fetching a PR head-ref needs a real remote
      // URL, and `git fetch '' <ref>` would silently target the wrong remote.
      if (authUrl == null || authUrl.isEmpty) {
        throw StateError('Cannot check out $headRef without an auth URL');
      }
      final fetch = await _git.run(
        [..._fetchCmd, authUrl, headRef],
        workdir: sourcePath,
        env: authEnv,
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
      // A fresh `git worktree add` checkout carries no untracked cruft, but scrub
      // anyway when pristine is requested so hooks-generated files can't linger.
      if (pristine) {
        await _scrubToHead(destPath);
      }
      CcInfraLog.warning(
        'Provisioned PR worktree via git worktree '
        '(touched source .git): $destPath on $branch',
      );
      return RepoIsolationResult(
        path: destPath,
        backend: RepoIsolationBackend.gitWorktree,
      );
    }

    // Refresh latest default branch into FETCH_HEAD only — never rewrite
    // origin/main in the user's source repo (that dest refspec is what
    // deletes origin/main and trips the lock). Touches source .git; accepted
    // only on this fallback path.
    final fetched = await _fetchToFetchHead(
      workdir: sourcePath,
      authUrl: authUrl,
      authEnv: authEnv,
      ref: baseRef,
    );

    final startPoints = [
      if (fetched) 'FETCH_HEAD',
      'refs/remotes/origin/$baseRef',
      if (baseRef.isNotEmpty) baseRef,
      'HEAD',
    ];
    for (final start in startPoints) {
      if (start == 'HEAD') {
        CcInfraLog.warning(
          'no default-branch start point for $destPath; '
          'worktree will use the source HEAD',
        );
      }
      final res = await _git.run(
        ['worktree', 'add', '-b', branch, destPath, start],
        workdir: sourcePath,
        env: _baseEnv,
      );
      if (res.isSuccess) {
        CcInfraLog.warning(
          'Provisioned via git worktree (touched source .git): '
          '$destPath on $branch',
        );
        return RepoIsolationResult(
          path: destPath,
          backend: RepoIsolationBackend.gitWorktree,
        );
      }
    }
    throw StateError('git worktree add failed for $destPath');
  }

  /// Reads the source repo's default branch without mutating it.
  ///
  /// Never uses the currently checked-out branch: a source on `feat/foo`
  /// must still provision off `main` / `master`.
  Future<String> _resolveDefaultBranch(String sourcePath) async {
    final originHead = await _git.run([
      'symbolic-ref',
      '--short',
      'refs/remotes/origin/HEAD',
    ], workdir: sourcePath);
    if (originHead.isSuccess) {
      final ref = originHead.stdout.trim();
      final slash = ref.lastIndexOf('/');
      final name = slash >= 0 ? ref.substring(slash + 1) : ref;
      if (name.isNotEmpty) {
        return name;
      }
    }
    if (await _remoteBranchExists(sourcePath, 'main')) {
      return 'main';
    }
    if (await _remoteBranchExists(sourcePath, 'master')) {
      return 'master';
    }
    return 'main';
  }

  Future<bool> _remoteBranchExists(String workdir, String name) async {
    final res = await _git.run([
      'show-ref',
      '--verify',
      '--quiet',
      'refs/remotes/origin/$name',
    ], workdir: workdir);
    return res.isSuccess;
  }

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async {
    // Rescue any uncommitted agent work BEFORE tearing the worktree down, so a
    // ticket/conversation/PR-end GC never silently discards in-progress edits
    // (FINDINGS §11.2). Best-effort: a failure here never blocks the destroy.
    await _rescueUncommittedWork(path, branch);
    switch (backend) {
      case RepoIsolationBackend.rift:
        try {
          await _rift.remove(at: path);
        } on RiftException catch (e) {
          if (!e.isMissing) {
            CcInfraLog.warning('rift remove failed (${e.code}): ${e.message}');
          }
        }
        try {
          await _rift.gc();
        } on RiftException catch (e) {
          CcInfraLog.info('rift gc note: ${e.message}');
        }
        // Belt-and-suspenders: drop the directory if rift left it behind.
        final dir = Directory(path);
        if (dir.existsSync()) {
          try {
            await dir.delete(recursive: true);
          } catch (e) {
            CcInfraLog.warning(
              'rift gc: failed to remove leftover worktree dir $path: $e',
            );
          }
        }
      case RepoIsolationBackend.gitWorktree:
        final remove = await _git.run([
          'worktree',
          'remove',
          '--force',
          path,
        ], workdir: sourcePath);
        if (!remove.isSuccess) {
          CcInfraLog.warning('worktree remove failed: ${remove.stderr.trim()}');
        }
        if (branch != null && branch.isNotEmpty) {
          await _git.run(['branch', '-D', branch], workdir: sourcePath);
        }
    }
  }

  /// Best-effort rescue of uncommitted work in the worktree at [path] before it
  /// is GC'd (FINDINGS §11.2). When the tree is dirty, stages + commits the
  /// changes (with an injected identity so it works even without a configured
  /// git user) and labels the commit with a `rescue/…` branch — which survives
  /// even when the working [branch] is deleted on the git-worktree teardown
  /// path, so an operator can recover the work.
  ///
  /// ALWAYS returns without throwing: a rescue failure must never block the
  /// destroy (that would re-introduce the worktree/disk leak fixed in §1), and
  /// the worst case is exactly the prior behaviour — the WIP is lost. On the
  /// rift CoW backend the commit lands in the copy's git; whether the rescue
  /// branch outlives `rift remove` depends on rift's object sharing, so this is
  /// a guaranteed rescue on the git-worktree path and best-effort on rift.
  Future<void> _rescueUncommittedWork(String path, String? branch) async {
    try {
      if (!Directory(path).existsSync()) {
        return;
      }
      final status = await _git.run(['status', '--porcelain'], workdir: path);
      if (!status.isSuccess || status.stdout.trim().isEmpty) {
        return; // clean, or status couldn't be read — nothing to rescue
      }
      final add = await _git.run(['add', '-A'], workdir: path);
      if (!add.isSuccess) {
        CcInfraLog.warning(
          'WIP rescue: `git add` failed at $path, skipping '
          '(proceeding to GC): ${add.stderr.trim()}',
        );
        return;
      }
      final commit = await _git.run([
        '-c',
        'user.email=rescue@control-center.local',
        '-c',
        'user.name=Control Center',
        'commit',
        '--no-verify',
        '-m',
        'chore: rescued uncommitted work before worktree GC',
      ], workdir: path);
      if (!commit.isSuccess) {
        CcInfraLog.warning(
          'WIP rescue: `git commit` failed at $path, skipping '
          '(proceeding to GC): ${commit.stderr.trim()}',
        );
        return;
      }
      final label = _rescueBranchName(branch);
      final made = await _git.run(['branch', label], workdir: path);
      if (made.isSuccess) {
        CcInfraLog.info(
          'WIP rescue: uncommitted changes at $path committed and '
          'preserved on branch $label',
        );
      } else {
        // The commit already preserves the work on the current branch; the
        // rescue label is a convenience, so a labelling failure is non-fatal.
        CcInfraLog.info(
          'WIP rescue: committed uncommitted changes at $path '
          '(rescue-branch label failed: ${made.stderr.trim()})',
        );
      }
    } on Object catch (e) {
      CcInfraLog.warning('WIP rescue before GC failed (proceeding to GC): $e');
    }
  }

  /// A filesystem-safe, collision-resistant `rescue/…` branch name derived from
  /// the working [branch] (or `worktree` when absent).
  String _rescueBranchName(String? branch) {
    final base = (branch == null || branch.isEmpty)
        ? 'worktree'
        : branch.replaceAll(RegExp('[^A-Za-z0-9._/-]'), '-');
    return 'rescue/$base-${DateTime.now().millisecondsSinceEpoch}';
  }
}
