import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;

/// [RepoIsolationPort] backed by the bundled rift CoW library.
///
/// **The source repo is never written to.** That is the invariant this class
/// exists to hold, and wherever rift ships, copy-on-write is the SOLE backend:
/// the CoW copy is created first and every git command after it — fetch,
/// branch, checkout, clean, the pre-teardown WIP rescue — runs INSIDE that
/// copy. The CoW path does not even read the source with git: the default
/// branch is resolved from the copy, which carries the same refs.
///
/// The one thing that does land in the source is rift's own `.rift` marker,
/// naming the source's registry entry. That marker is what makes a CoW copy
/// possible at all, and it is a single untracked dotfile — not a branch, not
/// history, not `.git` state.
///
/// **A CoW failure is a failure, not a fallback.** `git worktree add` on the
/// source writes the new branch, a `.git/worktrees/<name>` registration and
/// FETCH_HEAD into the user's checkout, and the label a teardown rescue writes
/// lands there too, because a linked worktree shares the source's ref
/// namespace. Doing that behind the operator's back is worse than not
/// provisioning at all, so `cow_unavailable` (a filesystem that cannot
/// reflink, or a data dir on a different volume from the repo) and every
/// operational rift error now PROPAGATE. The fix is a data dir on the same CoW
/// volume — not a slower backend that quietly pollutes a checkout.
///
/// `git worktree` therefore survives in exactly two places, each writing to the
/// source only where there is no alternative:
///   * [_worktreeFallback], reachable only on a platform that ships no rift and
///     never will (`missingRiftIsExpected`, i.e. Windows — no MSVC CoW
///     backend). There it is the BACKEND, not a degradation.
///   * [destroy], for a persisted `gitWorktree` row — including rows minted by
///     the fallback this class used to have. That teardown REMOVES source-repo
///     state, so it stays on every platform.
///
/// Everything rift can report about the SOURCE is repaired in place rather than
/// failed on. In particular a `.rift` marker this registry does not recognise
/// (left by another registry file, or surviving a data-dir reset) is cleared
/// and re-adopted: the marker lives in the user's repo and never expires, so
/// giving up on it would lock that repo out of CoW for good.
///
/// A missing `librift_ffi` on a platform that ships it is a BROKEN INSTALL and
/// propagates as `RiftException(code: 'unavailable')`; `cc_server` refuses to
/// boot on it in the first place (see its native preflight).
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
  ///
  /// [wipRescueDir] is where the pre-teardown WIP capture is written — a
  /// directory OUTSIDE any checkout, normally under the server data dir. When
  /// it is null the capture is skipped entirely: see
  /// [_rescueUncommittedWork] for why there is no improvised fallback
  /// location.
  RiftRepoIsolationAdapter({
    required RiftClient rift,
    required GitCommandPort git,
    bool? missingRiftIsExpected,
    String? wipRescueDir,
  }) : _rift = rift,
       _git = git,
       _wipRescueDir = wipRescueDir,
       _missingRiftIsExpected = missingRiftIsExpected ?? Platform.isWindows;

  final RiftClient _rift;
  final GitCommandPort _git;

  /// Where the pre-teardown WIP capture lands. Never inside a checkout.
  final String? _wipRescueDir;

  /// Whether an unloadable `librift_ffi` is a supported platform gap (Windows)
  /// rather than a broken install.
  final bool _missingRiftIsExpected;

  /// Total bytes of untracked files one WIP capture may copy. A teardown must
  /// stay a teardown: an agent that dropped a multi-gigabyte artifact in its
  /// worktree must not turn every GC into a long copy.
  static const _rescueByteBudget = 64 * 1024 * 1024;

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
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    await Directory(destParentDir).create(recursive: true);
    final auth = _resolveAuth(authUrl);

    if (!_rift.isAvailable) {
      if (!_missingRiftIsExpected) {
        // Broken install, not an environment gap — fail loudly rather than
        // provisioning a git worktree that writes into the user's checkout and
        // hides the broken native behind a slower path forever.
        throw _unavailable;
      }
      // The one platform that ships no CoW backend at all. `git worktree` is
      // the BACKEND here, and this is the only provisioning path in the class
      // that touches the source repo — see the class doc.
      return _worktreeFallback(
        sourcePath: sourcePath,
        destParentDir: destParentDir,
        name: name,
        branch: branch,
        baseRef: await _startRef(sourcePath, baseRef, headRef, cancel: cancel),
        authUrl: auth.url,
        authEnv: auth.env,
        headRef: headRef,
        pristine: pristine,
        cancel: cancel,
      );
    }

    // CoW or nothing. Every failure below propagates: the only other way to
    // materialize a worktree writes branches, worktree metadata and FETCH_HEAD
    // into the user's repo, which is not a fallback worth having.
    final String copyPath;
    try {
      copyPath = await _riftCreate(sourcePath, destParentDir, name);
    } on RiftException catch (e) {
      _explainNoFallback(e, sourcePath, destParentDir);
      rethrow;
    }
    cancel?.throwIfCancelled();
    await _fetchAndBranch(
      worktree: copyPath,
      branch: branch,
      // Resolved from the COPY, which carries the source's refs verbatim — so
      // the answer is identical and git never even reads the source.
      baseRef: await _startRef(copyPath, baseRef, headRef, cancel: cancel),
      authUrl: auth.url,
      authEnv: auth.env,
      headRef: headRef,
      cancel: cancel,
    );
    if (pristine) {
      await _scrubToHead(copyPath, cancel: cancel);
    }
    return RepoIsolationResult(
      path: copyPath,
      backend: RepoIsolationBackend.rift,
    );
  }

  /// The ref a new branch starts from, read out of [workdir].
  ///
  /// An explicit [baseRef] wins; the [headRef] path checks out fetched commits
  /// directly and needs no base at all, so the default-branch probe is skipped
  /// there rather than run for a value nothing reads.
  Future<String> _startRef(
    String workdir,
    String baseRef,
    String? headRef, {
    CancellationToken? cancel,
  }) async {
    if ((headRef != null && headRef.isNotEmpty) || baseRef.isNotEmpty) {
      return baseRef;
    }
    return _resolveDefaultBranch(workdir, cancel: cancel);
  }

  /// Logs WHY a rift failure ends the provision, so an operator gets the fix
  /// rather than a bare error code from a path that used to silently succeed.
  void _explainNoFallback(
    RiftException e,
    String sourcePath,
    String destParentDir,
  ) {
    if (e.isUnsafeGit) {
      // Self-explanatory and actionable already: the source is mid-merge or
      // mid-rebase, and no backend could have copied it safely.
      return;
    }
    if (e.isCowUnavailable) {
      CcInfraLog.warning(
        'copy-on-write copy of $sourcePath into $destParentDir failed: the '
        'filesystem cannot reflink, or the two are on different volumes. Put '
        'the server data dir on the same copy-on-write volume as the repo — '
        'there is no git-worktree fallback, because that backend writes '
        'branches, worktree metadata and FETCH_HEAD into the source repo.',
      );
      return;
    }
    CcInfraLog.warning(
      'rift create failed for $sourcePath (${e.code}): ${e.message}. There is '
      'no git-worktree fallback on a platform that ships rift — that backend '
      'writes into the source repo.',
    );
  }

  /// Scrubs the worktree to exactly its checked-out tree: removes untracked and
  /// ignored files (`git clean -ffdx`) that a `copyAll` CoW copy inherited from
  /// the source working dir. Best-effort — a clean failure must not fail the
  /// provision (the worst case is the prior behaviour: leftover cruft).
  Future<void> _scrubToHead(
    String worktree, {
    CancellationToken? cancel,
  }) async {
    if (!await _isCheckoutRoot(worktree)) {
      CcInfraLog.warning(
        'pristine clean skipped: $worktree is not the root of its own checkout '
        '(a `git clean -ffdx` there would delete files from the enclosing '
        'repo).',
      );
      return;
    }
    final res = await _git.run(
      [..._noCred, 'clean', '-ffdx'],
      workdir: worktree,
      env: _baseEnv,
      cancel: cancel,
    );
    cancel?.throwIfCancelled();
    if (!res.isSuccess) {
      CcInfraLog.warning(
        'pristine clean failed for $worktree: ${res.stderr.trim()}',
      );
    }
  }

  /// Whether [path] is the ROOT of its own checkout (a repo or a linked
  /// worktree), rather than a plain directory that merely SITS inside one.
  ///
  /// This is the difference between operating on an isolated copy and
  /// operating on the user's repo. **Git discovers its repository by walking
  /// UP from the working directory**, so `status` / `add -A` / `commit` /
  /// `clean -ffdx` / `checkout -B` issued in a directory that is not itself a
  /// checkout silently answer for whatever ENCLOSES it — and the server's data
  /// dir is routinely inside a repo (`<repo>/apps/cc_server/data/…`). A
  /// half-provisioned directory, or a copy whose `.git` a partial teardown
  /// removed, is therefore indistinguishable from the operator's own checkout
  /// unless something asks. That is how a teardown put eight
  /// `chore: rescued uncommitted work before worktree GC` commits, each
  /// carrying the whole working tree, onto a user's own branch.
  ///
  /// A negative answer is never a reason to guess: every caller either skips
  /// (the best-effort ones) or throws.
  Future<bool> _isCheckoutRoot(String path) async {
    if (!Directory(path).existsSync()) {
      return false;
    }
    final top = await _git.run(
      [..._noCred, 'rev-parse', '--show-toplevel'],
      workdir: path,
      env: _baseEnv,
    );
    final resolved = top.stdout.trim();
    if (!top.isSuccess || resolved.isEmpty) {
      return false;
    }
    return _canonical(resolved) == _canonical(path);
  }

  /// [path] with symlinks resolved, so `/var/…` and `/private/var/…` (macOS) or
  /// a checkout reached through a symlinked parent compare equal. Falls back to
  /// lexical normalisation for a path that is not on disk.
  String _canonical(String path) {
    try {
      return Directory(path).resolveSymbolicLinksSync();
    } on FileSystemException {
      return p.normalize(p.absolute(path));
    }
  }

  /// Runs `rift init` (idempotent) then `rift create`, retrying once if the
  /// source turns out not to be registered yet, carries a marker this registry
  /// does not know, or the destination is claimed by a registry entry whose
  /// directory is gone.
  Future<String> _riftCreate(
    String sourcePath,
    String destParentDir,
    String name,
  ) async {
    await _initSource(sourcePath);
    try {
      return await _create(sourcePath, destParentDir, name);
    } on RiftException catch (e) {
      if (e.isAlreadyExists) {
        // rift's `path` column is UNIQUE, so `already_exists` is a REGISTRY
        // verdict, not a filesystem one. When the directory is gone the entry
        // outlived what it described and nothing expires it on its own: every
        // later create at that path is refused and silently degrades to `git
        // worktree`, stranding it on the slow backend for ever. Prune and
        // retry — the same recovery [isStaleMarker] already gets, for the same
        // reason.
        if (await _pruneStaleRegistryEntry(destParentDir, name)) {
          return _create(sourcePath, destParentDir, name);
        }
        rethrow;
      }
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

  /// Drops a registry entry for `<destParentDir>/<name>` whose directory no
  /// longer exists, so the path can be created again on the CoW backend.
  ///
  /// Refuses when the directory IS there: a live managed copy is somebody's
  /// worktree, and tearing it down from inside a create is not this layer's
  /// call — the caller reaps an orphaned directory before provisioning.
  /// Returns whether the path is now free.
  Future<bool> _pruneStaleRegistryEntry(String destParentDir, String name) async {
    final destPath = p.join(destParentDir, name);
    if (Directory(destPath).existsSync()) {
      return false;
    }
    try {
      await _rift.remove(at: destPath);
    } on RiftException catch (e) {
      // `missing` is the expected answer for an entry with nothing behind it —
      // that is the case being repaired, so it is not a reason to stop.
      if (!e.isMissing) {
        CcInfraLog.warning(
          'could not release the stale rift entry for $destPath '
          '(${e.code}): ${e.message}',
        );
        return false;
      }
    } on Object catch (e) {
      CcInfraLog.warning('could not release the stale rift entry $destPath: $e');
      return false;
    }
    try {
      await _rift.gc();
    } on Object catch (e) {
      CcInfraLog.info('rift gc note while pruning $destPath: $e');
    }
    CcInfraLog.warning(
      'rift still claimed $destPath with no directory behind it; pruned the '
      'entry so the copy stays copy-on-write',
    );
    return true;
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
    CancellationToken? cancel,
  }) async {
    // Everything below runs `git` with [worktree] as the working directory, and
    // `checkout --force -B` there would move the ENCLOSING repo's HEAD and
    // discard its uncommitted work if this is not a checkout of its own. The
    // copy was just materialized, so a miss is a broken provision, not a case
    // to degrade through.
    if (!await _isCheckoutRoot(worktree)) {
      throw StateError(
        '$worktree is not the root of a git checkout; refusing to branch there '
        'because git would resolve the command against the enclosing repo.',
      );
    }

    // PR / explicit-ref path: fetch the requested ref to FETCH_HEAD, then point
    // [branch] at exactly that commit and check it out — so the copy lands on
    // the fetched commits (e.g. a PR head), never a fresh branch off the base.
    if (headRef != null && headRef.isNotEmpty) {
      // `_resolveAuth` normalises a missing/empty auth URL to '' (never null),
      // so guard on emptiness too — fetching a PR head-ref needs a real remote
      // URL and `git fetch '' <ref>` would silently target the wrong remote.
      if (authUrl == null || authUrl.isEmpty) {
        throw StateError('Cannot check out $headRef without an auth URL');
      }
      final fetch = await _git.run(
        [..._fetchCmd, authUrl, headRef],
        workdir: worktree,
        env: authEnv,
        cancel: cancel,
      );
      // A killed fetch reports as a failure; say what actually happened rather
      // than surfacing "Failed to fetch" for work the operator stopped.
      cancel?.throwIfCancelled();
      if (!fetch.isSuccess) {
        throw StateError('Failed to fetch $headRef: ${fetch.stderr.trim()}');
      }
      // `-B` (re)creates [branch] at FETCH_HEAD even if it already exists or is
      // the current branch, guaranteeing the working tree matches the PR head.
      final checkout = await _git.run(
        [..._noCred, 'checkout', '--force', '-B', branch, 'FETCH_HEAD'],
        workdir: worktree,
        env: _baseEnv,
        cancel: cancel,
      );
      cancel?.throwIfCancelled();
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
      cancel: cancel,
    );
    cancel?.throwIfCancelled();

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
        cancel: cancel,
      );
      cancel?.throwIfCancelled();
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
      cancel: cancel,
    );
    cancel?.throwIfCancelled();
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
  Future<String?> _resolveFetchUrl(
    String? authUrl,
    String workdir, {
    CancellationToken? cancel,
  }) async {
    if (authUrl != null && authUrl.isNotEmpty) {
      return authUrl;
    }
    final remote = await _git.run(
      ['remote', 'get-url', 'origin'],
      workdir: workdir,
      cancel: cancel,
    );
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
    CancellationToken? cancel,
  }) async {
    if (ref.isEmpty) {
      return false;
    }
    final url = await _resolveFetchUrl(authUrl, workdir, cancel: cancel);
    if (url == null) {
      return false;
    }
    final fetch = await _git.run(
      [..._fetchCmd, url, ref],
      workdir: workdir,
      env: authEnv,
      cancel: cancel,
    );
    cancel?.throwIfCancelled();
    if (!fetch.isSuccess) {
      CcInfraLog.warning('fetch of $ref failed: ${fetch.stderr.trim()}');
    }
    return fetch.isSuccess;
  }

  /// The plain `git worktree` backend — reachable ONLY on a platform that
  /// ships no rift at all (Windows: no MSVC CoW backend), where it is the
  /// backend rather than a degradation.
  ///
  /// It is also the only provisioning code in this class that writes into the
  /// source repo: the fetch lands in the source's FETCH_HEAD, `worktree add`
  /// registers itself under the source's `.git/worktrees/`, and the branch it
  /// creates lives in the source's shared ref namespace (which is also why a
  /// teardown rescue label ends up there). That is precisely why a non-CoW
  /// filesystem and an operational rift error no longer reach it — see the
  /// class doc.
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
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final destPath = p.join(destParentDir, name);

    // PR / explicit-ref path: fetch the ref to the source's FETCH_HEAD (this
    // touches the source .git — accepted on the fallback path), then add a
    // worktree with [branch] (re)created at exactly that commit.
    if (headRef != null && headRef.isNotEmpty) {
      // `_resolveAuth` normalises a missing/empty auth URL to '' (never null),
      // so guard on emptiness too — fetching a PR head-ref needs a real remote
      // URL and `git fetch '' <ref>` would silently target the wrong remote.
      if (authUrl == null || authUrl.isEmpty) {
        throw StateError('Cannot check out $headRef without an auth URL');
      }
      final fetch = await _git.run(
        [..._fetchCmd, authUrl, headRef],
        workdir: sourcePath,
        env: authEnv,
        cancel: cancel,
      );
      cancel?.throwIfCancelled();
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
        cancel: cancel,
      );
      cancel?.throwIfCancelled();
      if (!add.isSuccess) {
        throw StateError(
          'git worktree add failed for $destPath: ${add.stderr.trim()}',
        );
      }
      // A fresh `git worktree add` checkout carries no untracked cruft, but scrub
      // anyway when pristine is requested so hooks-generated files can't linger.
      if (pristine) {
        await _scrubToHead(destPath, cancel: cancel);
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
      cancel: cancel,
    );
    cancel?.throwIfCancelled();

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
        cancel: cancel,
      );
      cancel?.throwIfCancelled();
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

  /// Reads a repo's default branch without mutating it.
  ///
  /// On the CoW path [workdir] is the COPY, not the user's checkout: it holds
  /// the same `refs/remotes/origin/*`, so the answer is identical and the
  /// source is never even read. Only the Windows worktree backend passes the
  /// real source, which it is already writing to anyway.
  ///
  /// Never uses the currently checked-out branch: a repo sitting on `feat/foo`
  /// must still provision off `main` / `master`.
  Future<String> _resolveDefaultBranch(
    String workdir, {
    CancellationToken? cancel,
  }) async {
    final originHead = await _git.run(
      ['symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
      workdir: workdir,
      cancel: cancel,
    );
    if (originHead.isSuccess) {
      final ref = originHead.stdout.trim();
      final slash = ref.lastIndexOf('/');
      final name = slash >= 0 ? ref.substring(slash + 1) : ref;
      if (name.isNotEmpty) {
        return name;
      }
    }
    if (await _remoteBranchExists(workdir, 'main', cancel: cancel)) {
      return 'main';
    }
    if (await _remoteBranchExists(workdir, 'master', cancel: cancel)) {
      return 'master';
    }
    return 'main';
  }

  Future<bool> _remoteBranchExists(
    String workdir,
    String name, {
    CancellationToken? cancel,
  }) async {
    final res = await _git.run(
      ['show-ref', '--verify', '--quiet', 'refs/remotes/origin/$name'],
      workdir: workdir,
      cancel: cancel,
    );
    return res.isSuccess;
  }

  /// Tears down a provisioned worktree.
  ///
  /// The `gitWorktree` branch runs on EVERY platform, not just the one that
  /// still provisions that way: rows minted by the fallback this class used to
  /// have are still on disk and in the registry, and their teardown is what
  /// REMOVES the worktree registration and branch from the user's repo. Losing
  /// it would strand that state — `.git/worktrees/<name>` entries and `conv/*`
  /// branches — in the checkout for good.
  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async {
    // Capture any uncommitted agent work BEFORE tearing the worktree down, so
    // a ticket/conversation/PR-end GC never silently discards in-progress
    // edits (FINDINGS §11.2). READ-ONLY — a patch under the data dir, never a
    // commit in a repo. Best-effort: a failure here never blocks the destroy.
    await _rescueUncommittedWork(path, sourcePath, branch);
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
            // And gc AGAIN. `gc` prunes entries whose directory is missing, so
            // the pass above — which ran while this directory was still there —
            // could not have pruned this one. Skipping the second pass is what
            // left registry entries claiming paths that no longer existed, and
            // every later create at such a path is refused (`already_exists`)
            // and silently degrades to `git worktree`.
            try {
              await _rift.gc();
            } on Object catch (e) {
              CcInfraLog.info('rift gc note after removing $path: $e');
            }
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
  /// is GC'd (FINDINGS §11.2), as a READ-ONLY capture written outside every
  /// checkout.
  ///
  /// **Nothing here mutates a git repository — there is no `add`, no `commit`,
  /// no `branch`.** This used to stage the worktree, commit it with an injected
  /// identity and label the result `rescue/…`. Every one of those three writes
  /// lands in the OPERATOR'S repo whenever the worktree shares its object and
  /// ref store, and two routine cases do:
  ///   * a linked `git worktree` shares the source's store BY DEFINITION, so
  ///     the commit and the `rescue/*` label were always the user's repo — the
  ///     old doc called that "a guaranteed rescue" and it is really a write
  ///     into a checkout nobody asked us to write to;
  ///   * a directory that is not a checkout of its own resolves to whatever
  ///     ENCLOSES it, and the server data dir routinely sits inside a repo
  ///     (`<repo>/apps/cc_server/data/…`) — which is how a run of
  ///     `chore: rescued uncommitted work before worktree GC` commits, each
  ///     carrying the whole working tree, landed on a user's own branch.
  ///
  /// Guarding the commit could not fix that. A guard is a claim about the
  /// path, and the path is precisely what was wrong; every guard added was
  /// followed by another commit through a route the guard did not model. So
  /// the commit is gone instead of guarded, and the mutating verbs are no
  /// longer reachable from the teardown path at all.
  ///
  /// What replaces it preserves the same work with no side effect on any repo:
  /// `git diff --binary HEAD` for tracked edits, plus a copy of the untracked
  /// files (`.gitignore` honoured, bounded by [_rescueByteBudget]), written
  /// under [_wipRescueDir] with a `RESTORE.txt` naming the worktree and branch
  /// it came from. Recovery is `git apply changes.patch` and copying
  /// `untracked/` back — an operator action, in a repo of their choosing.
  ///
  /// The identity and checkout-root probes stay even though nothing here
  /// writes: reading the SOURCE would capture the operator's own tree into a
  /// bogus rescue folder on every teardown, which is noise that looks exactly
  /// like the bug it replaced.
  ///
  /// ALWAYS returns without throwing: a rescue failure must never block the
  /// destroy (that would re-introduce the worktree/disk leak fixed in §1) and
  /// the worst case is exactly the prior behaviour — the WIP is lost.
  Future<void> _rescueUncommittedWork(
    String path,
    String sourcePath,
    String? branch,
  ) async {
    final rescueRoot = _wipRescueDir;
    if (rescueRoot == null || rescueRoot.isEmpty) {
      // Deliberately no fallback location. The only directories in reach here
      // are the worktree (about to be deleted) and the source repo (the thing
      // this must never write to), so "somewhere is better than nowhere" is
      // how the capture ends up in the user's checkout again.
      return;
    }
    try {
      if (_canonical(path) == _canonical(sourcePath)) {
        CcInfraLog.warning(
          'WIP rescue: refusing to read $path — that is the source repo, not '
          'an isolated copy.',
        );
        return;
      }
      if (!await _isCheckoutRoot(path)) {
        // Covers "the directory is gone" too, so no separate existence probe.
        // A `git diff` here would describe the ENCLOSING repo's working tree.
        return;
      }
      final status = await _git.run(
        [..._noCred, 'status', '--porcelain'],
        workdir: path,
        env: _baseEnv,
      );
      if (!status.isSuccess || status.stdout.trim().isEmpty) {
        return; // clean, or status couldn't be read — nothing to rescue
      }

      final out = Directory(p.join(rescueRoot, _rescueFolderName(branch)));
      await out.create(recursive: true);

      // Tracked edits. `--binary` keeps a modified binary file applicable
      // instead of degrading to a "Binary files differ" stub the patch cannot
      // restore from.
      var patchBytes = 0;
      final diff = await _git.run(
        [..._noCred, 'diff', '--binary', 'HEAD'],
        workdir: path,
        env: _baseEnv,
      );
      if (diff.isSuccess && diff.stdout.isNotEmpty) {
        final patch = File(p.join(out.path, 'changes.patch'));
        await patch.writeAsString(diff.stdout);
        patchBytes = diff.stdout.length;
      }

      final untracked = await _copyUntrackedFiles(path, out.path);

      await File(p.join(out.path, 'RESTORE.txt')).writeAsString(
        'Uncommitted work captured before the worktree below was garbage '
        'collected.\n'
        '\n'
        'worktree: $path\n'
        'source:   $sourcePath\n'
        'branch:   ${branch ?? '(none)'}\n'
        '\n'
        'Nothing was committed and no branch was created — the capture is '
        'read-only\n'
        'by design, so recovery is yours to run, in a repo you choose:\n'
        '\n'
        '  git apply /path/to/changes.patch     # tracked edits\n'
        '  cp -R untracked/. <your-checkout>/   # files git was not '
        'tracking\n',
      );

      CcInfraLog.info(
        'WIP rescue: uncommitted work at $path captured read-only in '
        '${out.path} ($patchBytes B patch, $untracked untracked file(s)); no '
        'commit and no branch were created.',
      );
    } on Object catch (e) {
      CcInfraLog.warning('WIP rescue before GC failed (proceeding to GC): $e');
    }
  }

  /// Copies the worktree's untracked, non-ignored files into `untracked/`
  /// under [destDir] and returns how many were copied. Read-only with respect
  /// to the repo: `ls-files --others` neither stages nor writes an object.
  ///
  /// Bounded by [_rescueByteBudget], because this runs on the teardown path.
  /// A skipped file is LOGGED rather than dropped silently — "the rescue
  /// folder exists" must not be read as "everything is in it".
  Future<int> _copyUntrackedFiles(String worktree, String destDir) async {
    final listed = await _git.run(
      [..._noCred, 'ls-files', '--others', '--exclude-standard', '-z'],
      workdir: worktree,
      env: _baseEnv,
    );
    if (!listed.isSuccess) {
      return 0;
    }
    var budget = _rescueByteBudget;
    var copied = 0;
    var skipped = 0;
    // NUL-separated (`-z`), so a path containing a space or a newline survives
    // the round trip — git's default output would hand back a quoted string.
    for (final rel in listed.stdout.split('\u0000')) {
      if (rel.isEmpty) {
        continue;
      }
      final src = File(p.join(worktree, rel));
      if (!src.existsSync()) {
        continue; // a symlink to nowhere, or deleted since `ls-files` ran
      }
      final len = src.lengthSync();
      if (len > budget) {
        skipped++;
        continue;
      }
      final dst = File(p.join(destDir, 'untracked', rel));
      await dst.parent.create(recursive: true);
      await src.copy(dst.path);
      budget -= len;
      copied++;
    }
    if (skipped > 0) {
      CcInfraLog.warning(
        'WIP rescue: $skipped untracked file(s) at $worktree exceeded the '
        '${_rescueByteBudget ~/ (1024 * 1024)} MB capture budget and were NOT '
        'copied.',
      );
    }
    return copied;
  }

  /// A filesystem-safe, collision-resistant folder name for one capture,
  /// derived from the working [branch] (or `worktree` when absent). Slashes
  /// are flattened: a branch like `conv/abc` must not become a nested path
  /// under the rescue root.
  String _rescueFolderName(String? branch) {
    final base = (branch == null || branch.isEmpty)
        ? 'worktree'
        : branch.replaceAll(RegExp('[^A-Za-z0-9._-]'), '-');
    return '$base-${DateTime.now().millisecondsSinceEpoch}';
  }
}
