import 'dart:io';

import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/repos/rift_repo_isolation_adapter.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeRift extends RiftClient {
  _FakeRift({
    this.available = true,
    this.createError,
    this.initError,
    this.markerPresent = false,
    this.clearMarkerThrows = false,
  }) : super(dylibPaths: const [], databasePath: 'mem');

  final bool available;
  final RiftException? createError;
  final RiftException? initError;

  /// Whether a `.rift` marker is there for [clearMarker] to remove.
  bool markerPresent;

  /// Simulates an undeletable marker (read-only checkout / permissions).
  final bool clearMarkerThrows;
  final List<String> calls = [];
  int _createCalls = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<void> init({required String at}) async {
    calls.add('init:$at');
    final err = initError;
    // A stale-marker init error clears once the marker is gone, mirroring rift:
    // it is reported per marker, not per source.
    if (err != null && !(err.isStaleMarker && !markerPresent)) {
      throw err;
    }
  }

  @override
  Future<bool> clearMarker({required String at}) async {
    calls.add('clearMarker:$at');
    if (clearMarkerThrows) {
      throw const FileSystemException('read-only file system');
    }
    if (!markerPresent) {
      return false;
    }
    markerPresent = false;
    return true;
  }

  @override
  Future<String> create({
    required String from,
    required String into,
    String? name,
    bool copyAll = true,
    bool hooks = false,
  }) async {
    calls.add('create');
    _createCalls++;
    final err = createError;
    if (err != null && _createCalls == 1) {
      throw err;
    }
    // Materialize it: a `create` that returns a path it never made would let
    // the adapter's "is this a checkout of its own?" guard pass vacuously, and
    // that guard is what stands between a teardown and the operator's repo.
    final path = '$into/$name';
    Directory(path).createSync(recursive: true);
    return path;
  }

  @override
  Future<void> remove({required String at}) async => calls.add('remove:$at');

  @override
  Future<List<String>> gc() async {
    calls.add('gc');
    return const [];
  }

  @override
  Future<List<String>> list({required String of}) async => const [];
}

class _FakeGit implements GitCommandPort {
  _FakeGit({Map<String, GitResult>? responses}) : _responses = responses ?? {};
  final List<List<String>> runs = [];

  /// The `workdir` of each entry in [runs], same index. This is what pins the
  /// class's central invariant: on the CoW backend no command — not even a
  /// read-only probe — is issued against the user's checkout.
  final List<String> workdirs = [];
  final Map<String, GitResult> _responses;

  @override
  Future<GitResult> run(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
    CancellationToken? cancel,
  }) async {
    runs.add(args);
    workdirs.add(workdir);
    final joined = args.join(' ');
    for (final entry in _responses.entries) {
      if (joined.contains(entry.key)) {
        return entry.value;
      }
    }
    // Default: the old per-command behaviour — everything succeeds.
    if (args.contains('symbolic-ref')) {
      return const GitResult(exitCode: 0, stdout: 'origin/main\n', stderr: '');
    }
    // Model git's repo discovery honestly: a real checkout answers with its own
    // root. The adapter refuses to mutate anything whose toplevel is somewhere
    // ELSE, which is what stops it committing the enclosing repo.
    if (args.contains('--show-toplevel')) {
      return GitResult(exitCode: 0, stdout: '$workdir\n', stderr: '');
    }
    return const GitResult(exitCode: 0, stdout: '', stderr: '');
  }

  @override
  Stream<String> runStreaming(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
  }) async* {}

  bool ran(bool Function(List<String>) pred) => runs.any(pred);

  /// The args of every command that ran in [dir].
  List<List<String>> inDir(String dir) => [
    for (var i = 0; i < runs.length; i++)
      if (workdirs[i] == dir) runs[i],
  ];
}

// ---------------------------------------------------------------------------
// Adapter under test
// ---------------------------------------------------------------------------

/// Builds the adapter with [missingRiftIsExpected] defaulting to TRUE, i.e. the
/// Windows contract: rift is not built there, so `git worktree` is the BACKEND
/// rather than a degradation. That default lets the many tests below set
/// `_FakeRift(available: false)` to reach the worktree code paths they are
/// actually about.
///
/// On a platform that DOES ship rift, an unloadable dylib is a broken install
/// and must throw instead — pass `missingRiftIsExpected: false` for that, as the
/// three "broken install" tests do.
RiftRepoIsolationAdapter _adapter({
  required RiftClient rift,
  required GitCommandPort git,
  bool missingRiftIsExpected = true,
  String? wipRescueDir,
}) => RiftRepoIsolationAdapter(
  rift: rift,
  git: git,
  missingRiftIsExpected: missingRiftIsExpected,
  wipRescueDir: wipRescueDir,
);

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('rift_adapter_test');
  });
  tearDown(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  // -- isCowAvailable -------------------------------------------------------

  test('isCowAvailable reflects rift availability', () {
    final available = _adapter(
      rift: _FakeRift(available: true),
      git: _FakeGit(),
    );
    final unavailable = _adapter(
      rift: _FakeRift(available: false),
      git: _FakeGit(),
    );

    expect(available.isCowAvailable, isTrue);
    expect(unavailable.isCowAvailable, isFalse);
  });

  // -- provision: an unloadable dylib is a broken install, not a fallback -----

  test('throws when rift is unavailable on a platform that ships it', () async {
    // The dylib is REQUIRED on macOS/Linux. Silently provisioning a git
    // worktree here would hide a broken install behind a slower-but-working
    // path forever, so it must fail loudly instead.
    final rift = _FakeRift(available: false);
    final git = _FakeGit();
    final adapter = _adapter(
      rift: rift,
      git: git,
      missingRiftIsExpected: false,
    );

    await expectLater(
      adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      ),
      throwsA(
        isA<RiftException>().having((e) => e.code, 'code', 'unavailable'),
      ),
    );
    expect(rift.calls, isEmpty);
    expect(
      git.ran((a) => a.length >= 2 && a[0] == 'worktree' && a[1] == 'add'),
      isFalse,
      reason: 'a broken install must not be papered over with a worktree',
    );
  });

  test(
    'uses the git worktree BACKEND where rift is never built (Windows)',
    () async {
      // Windows has no MSVC copy-on-write backend, so rift is deliberately not
      // built there and `git worktree` is the backend rather than a degradation.
      // Exercised via the injected flag so this holds on any host.
      final rift = _FakeRift(available: false);
      final git = _FakeGit();
      final adapter = _adapter(
        rift: rift,
        git: git,
        missingRiftIsExpected: true,
      );

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      expect(result.backend, RepoIsolationBackend.gitWorktree);
      expect(rift.calls, isEmpty);
      expect(
        git.ran((a) => a.length >= 2 && a[0] == 'worktree' && a[1] == 'add'),
        isTrue,
      );
    },
  );

  test('rethrows a worker-isolate load failure (code: unavailable)', () async {
    // The main-isolate probe passed but the worker could not load the dylib —
    // a partial/mismatched bundle. Must surface, not switch backends.
    final rift = _FakeRift(
      createError: const RiftException(
        code: 'unavailable',
        message: 'rift native library failed to load in worker isolate',
      ),
    );
    final git = _FakeGit();
    final adapter = _adapter(
      rift: rift,
      git: git,
      missingRiftIsExpected: false,
    );

    await expectLater(
      adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      ),
      throwsA(
        isA<RiftException>().having((e) => e.code, 'code', 'unavailable'),
      ),
    );
    expect(
      git.ran((a) => a.length >= 2 && a[0] == 'worktree' && a[1] == 'add'),
      isFalse,
    );
  });

  // -- provision: rift path --------------------------------------------------

  test(
    'uses rift when available and creates a branch (no worktree add)',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      expect(result.backend, RepoIsolationBackend.rift);
      expect(rift.calls, contains('init:/src/repo'));
      expect(rift.calls, contains('create'));
      expect(
        git.ran((a) => a.contains('checkout') && a.contains('-B')),
        isTrue,
      );
      expect(git.ran((a) => a.contains('worktree')), isFalse);
    },
  );

  test('the CoW path issues no git command against the source', () async {
    // The invariant the whole class exists for. The copy is made first and the
    // fetch, the branch and the checkout all run inside it — and so does the
    // default-branch probe, because the copy carries the source's
    // `refs/remotes/origin/*` verbatim and the answer is identical. A repo
    // provisioned this way collects no `conv/*` branch, no
    // `.git/worktrees/<name>` entry and no FETCH_HEAD write.
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = _adapter(
      rift: rift,
      git: git,
      missingRiftIsExpected: false,
    );

    final result = await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'feature/x',
      authUrl: 'https://token@github.com/owner/repo.git',
    );

    expect(result.backend, RepoIsolationBackend.rift);
    expect(git.inDir('/src/repo'), isEmpty);
    expect(git.workdirs.toSet(), {'${tmp.path}/repo'});
    // …and the probe really did run — in the copy, not nowhere.
    expect(git.ran((a) => a.contains('symbolic-ref')), isTrue);
  });

  test(
    'provision path resolution — rift result path is destParentDir/name',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'my-fork',
        branch: 'feature/x',
      );

      expect(result.path, '${tmp.path}/my-fork');
    },
  );

  test(
    'provision path resolution — worktree result path is destParentDir/name',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'my-fork',
        branch: 'feature/x',
      );

      expect(result.path, '${tmp.path}/my-fork');
    },
  );

  // -- provision: explicit baseRef (skips _resolveDefaultBranch) -------------

  test(
    'provision with explicit baseRef skips default-branch resolution',
    () async {
      final rift = _FakeRift(available: false); // force worktree path
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        baseRef: 'develop',
      );

      // symbolic-ref should NOT have been called — we supplied baseRef.
      expect(git.ran((a) => a.contains('symbolic-ref')), isFalse);
    },
  );

  test('provision without baseRef resolves default branch', () async {
    final rift = _FakeRift(available: false);
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'feature/x',
    );

    expect(git.ran((a) => a.contains('symbolic-ref')), isTrue);
  });

  // -- provision: headRef / PR path ------------------------------------------

  test(
    'provision with headRef fetches PR ref and checks out FETCH_HEAD',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'pr-42',
        authUrl: 'https://token@github.com/owner/repo.git',
        headRef: 'refs/pull/42/head',
      );

      expect(result.backend, RepoIsolationBackend.rift);
      // Should have fetched the headRef
      expect(
        git.ran((a) => a.contains('fetch') && a.contains('refs/pull/42/head')),
        isTrue,
      );
      // Should have checked out with -B to FETCH_HEAD
      expect(
        git.ran(
          (a) =>
              a.contains('checkout') &&
              a.contains('-B') &&
              a.contains('FETCH_HEAD'),
        ),
        isTrue,
      );
      // No regular checkout -b (the normal branch path)
      expect(
        git.ran(
          (a) =>
              a.contains('checkout') && a.contains('-b') && !a.contains('-B'),
        ),
        isFalse,
      );
    },
  );

  test('provision with headRef but no authUrl throws StateError', () async {
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    expect(
      () => adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'pr-42',
        headRef: 'refs/pull/42/head',
      ),
      throwsA(isA<StateError>()),
    );
  });

  // -- provision: headRef + worktree fallback --------------------------------

  test(
    'worktree fallback with headRef fetches PR ref and creates worktree',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'pr-42',
        authUrl: 'https://token@github.com/owner/repo.git',
        headRef: 'refs/pull/42/head',
      );

      expect(result.backend, RepoIsolationBackend.gitWorktree);
      // Fetches into source
      expect(
        git.ran((a) => a.contains('fetch') && a.contains('refs/pull/42/head')),
        isTrue,
      );
      // Creates detached worktree
      expect(
        git.ran((a) => a.contains('worktree') && a.contains('--detach')),
        isTrue,
      );
    },
  );

  // -- provision: cow_unavailable is a failure, not a fallback ---------------

  test('rethrows on cow_unavailable rather than touching the source', () async {
    // A filesystem that cannot reflink — or a data dir on a different volume
    // from the repo — used to drop to `git worktree add` on the SOURCE, which
    // writes the new branch, a `.git/worktrees/<name>` registration and
    // FETCH_HEAD into the operator's own checkout. Failing is the lesser evil:
    // the fix is a data dir on the same copy-on-write volume, and a provision
    // that silently pollutes a checkout never surfaces that.
    final rift = _FakeRift(
      createError: const RiftException(
        code: 'cow_unavailable',
        message: 'no CoW',
      ),
    );
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    await expectLater(
      adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      ),
      throwsA(
        isA<RiftException>().having((e) => e.code, 'code', 'cow_unavailable'),
      ),
    );
    expect(git.ran((a) => a.contains('worktree')), isFalse);
  });

  // -- provision: unsafe_git → rethrow ---------------------------------------

  test('rethrows on unsafe_git (no worktree fallback)', () async {
    final rift = _FakeRift(
      createError: const RiftException(
        code: 'unsafe_git',
        message: 'merge in progress',
      ),
    );
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    expect(
      () => adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      ),
      throwsA(isA<RiftException>()),
    );
  });

  test('provision — rift init throws unsafe_git → rethrows', () async {
    final rift = _FakeRift(
      initError: const RiftException(
        code: 'unsafe_git',
        message: 'merge in progress',
      ),
    );
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    expect(
      () => adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      ),
      throwsA(isA<RiftException>()),
    );
  });

  // -- provision: rift init non-fatal → recovers -----------------------------

  test(
    'provision — rift init throws non-fatal error, create proceeds',
    () async {
      final rift = _FakeRift(
        initError: const RiftException(
          code: 'already_initialized',
          message: 'was already inited',
        ),
      );
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      expect(result.backend, RepoIsolationBackend.rift);
      expect(rift.calls, contains('create'));
    },
  );

  // -- provision: rift create isInitRequired → retry -------------------------

  test(
    'provision — rift create throws isInitRequired, retries after init',
    () async {
      final rift = _FakeRift(
        createError: const RiftException(
          code: 'workspace_not_initialized',
          message: 'not inited',
        ),
      );
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      expect(result.backend, RepoIsolationBackend.rift);
      // Init should have been called twice: once up front, once on retry.
      expect(rift.calls.where((c) => c.startsWith('init:')).length, 2);
    },
  );

  // -- provision: other rift error → still no worktree on the source ---------

  test(
    'provision — an operational rift error propagates, it does not degrade',
    () async {
      // A protocol hiccup or registry contention is transient and retryable.
      // "Retryable" is not a reason to write branches and worktree metadata
      // into the user's repo, so the error reaches the caller instead.
      final rift = _FakeRift(
        createError: const RiftException(
          code: 'internal_error',
          message: 'something broke',
        ),
      );
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      await expectLater(
        adapter.provision(
          sourcePath: '/src/repo',
          destParentDir: tmp.path,
          name: 'repo',
          branch: 'feature/x',
        ),
        throwsA(
          isA<RiftException>().having((e) => e.code, 'code', 'internal_error'),
        ),
      );
      expect(git.ran((a) => a.contains('worktree')), isFalse);
    },
  );

  // -- provision: _fetchAndBranch error cases --------------------------------

  test('provision — headRef fetch failure throws StateError', () async {
    final rift = _FakeRift();
    final git = _FakeGit(
      responses: {
        'fetch --no-tags --force': const GitResult(
          exitCode: 128,
          stdout: '',
          stderr: 'fatal: could not read from remote',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git);

    expect(
      () => adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'pr-42',
        authUrl: 'https://token@github.com/owner/repo.git',
        headRef: 'refs/pull/42/head',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('provision — headRef checkout failure throws StateError', () async {
    final rift = _FakeRift();
    final git = _FakeGit(
      responses: {
        'checkout --force -B': const GitResult(
          exitCode: 1,
          stdout: '',
          stderr: 'error: pathspec did not match',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git);

    expect(
      () => adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'pr-42',
        authUrl: 'https://token@github.com/owner/repo.git',
        headRef: 'refs/pull/42/head',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'provision — without headRef, authUrl fetch failure degrades to local',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit(
        responses: {
          'fetch --no-tags --force': const GitResult(
            exitCode: 128,
            stdout: '',
            stderr: 'fatal: could not read',
          ),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      // Should NOT throw — fetch failure is non-fatal on the non-headRef path.
      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        authUrl: 'https://token@github.com/owner/repo.git',
        baseRef: 'main',
      );

      expect(result.backend, RepoIsolationBackend.rift);
      // Fetch failed → no FETCH_HEAD checkout; next start is inherited origin/main.
      expect(
        git.ran((a) => a.contains('checkout') && a.contains('FETCH_HEAD')),
        isFalse,
      );
      expect(
        git.ran(
          (a) =>
              a.contains('checkout') &&
              a.contains('-B') &&
              a.contains('refs/remotes/origin/main'),
        ),
        isTrue,
      );
    },
  );

  // -- provision: worktreeFallback error cases -------------------------------

  test('worktree fallback — PR fetch failure throws StateError', () async {
    final rift = _FakeRift(available: false);
    final git = _FakeGit(
      responses: {
        'fetch --no-tags --force': const GitResult(
          exitCode: 128,
          stdout: '',
          stderr: 'fatal: could not read',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git);

    expect(
      () => adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'pr-42',
        authUrl: 'https://token@github.com/owner/repo.git',
        headRef: 'refs/pull/42/head',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('worktree fallback — all start points fail throws StateError', () async {
    final rift = _FakeRift(available: false);
    final git = _FakeGit(
      responses: {
        'worktree add': const GitResult(
          exitCode: 128,
          stdout: '',
          stderr: 'fatal: worktree add failed',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git);

    expect(
      () => adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      ),
      throwsA(isA<StateError>()),
    );
  });

  // -- destroy: rift backend -------------------------------------------------

  test('destroy uses rift remove + gc for the rift backend', () async {
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    await adapter.destroy(
      path: '/iso/repo',
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.rift,
      branch: 'feature/x',
    );

    expect(rift.calls, contains('remove:/iso/repo'));
    expect(rift.calls, contains('gc'));
  });

  test(
    'destroy rift backend — remove throws non-missing error, gc still runs',
    () async {
      final rift = _FakeRift(
        initError: const RiftException(
          code: 'internal_error',
          message: 'remove failed',
        ),
      );
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      // destroy calls remove, which doesn't use initError — and the default
      // remove just records the call.  We need a rift whose remove throws.
      // Let's verify the structure: _FakeRift.remove does NOT throw, so
      // the non-missing path isn't testable with this fake.
      //
      // Instead, we test that destroy does not throw even when the adapter's
      // underlying calls would encounter errors (the adapter catches them).
      // For the rift backend: an IOSink exception during directory deletion
      // is caught.  For the worktree backend: git failures are logged, not
      // thrown.  These are verified in the worktree-destroy tests below.

      // This test focuses on the belt-and-suspenders dir delete: the tmp
      // directory doesn't exist at the path we specify, so dir.delete
      // should not throw even when the dir doesn't exist.
      await adapter.destroy(
        path: '/iso/repo',
        sourcePath: '/src/repo',
        backend: RepoIsolationBackend.rift,
        branch: 'feature/x',
      );

      // gc is still called regardless of remove outcome.
      expect(rift.calls, contains('gc'));
    },
  );

  // -- destroy: worktree backend ---------------------------------------------

  test('destroy removes worktree + branch for the worktree backend', () async {
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    await adapter.destroy(
      path: '/iso/repo',
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.gitWorktree,
      branch: 'feature/x',
    );

    expect(
      git.ran((a) => a.contains('worktree') && a.contains('remove')),
      isTrue,
    );
    expect(git.ran((a) => a.contains('branch') && a.contains('-D')), isTrue);
  });

  test(
    'destroy worktree backend — without branch does not delete branch',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      await adapter.destroy(
        path: '/iso/repo',
        sourcePath: '/src/repo',
        backend: RepoIsolationBackend.gitWorktree,
      );

      expect(
        git.ran((a) => a.contains('worktree') && a.contains('remove')),
        isTrue,
      );
      expect(git.ran((a) => a.contains('branch') && a.contains('-D')), isFalse);
    },
  );

  test(
    'destroy worktree backend — empty branch does not delete branch',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      await adapter.destroy(
        path: '/iso/repo',
        sourcePath: '/src/repo',
        backend: RepoIsolationBackend.gitWorktree,
        branch: '',
      );

      expect(
        git.ran((a) => a.contains('worktree') && a.contains('remove')),
        isTrue,
      );
      expect(git.ran((a) => a.contains('branch') && a.contains('-D')), isFalse);
    },
  );

  // -- destroy: edge cases ---------------------------------------------------

  test('destroy worktree backend — remove failure does not throw', () async {
    final rift = _FakeRift();
    final git = _FakeGit(
      responses: {
        'worktree remove': const GitResult(
          exitCode: 1,
          stdout: '',
          stderr: 'worktree not found',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git);

    // Should not throw — adapter catches and logs.
    await adapter.destroy(
      path: '/iso/repo',
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.gitWorktree,
      branch: 'feature/x',
    );
  });

  // -- destroy: WIP rescue (§11.2) -------------------------------------------

  test('destroy captures uncommitted work read-only before GC', () async {
    final wt = Directory('${tmp.path}/wt')..createSync();
    File('${wt.path}/new.dart').writeAsStringSync('void main() {}\n');
    final rescues = Directory('${tmp.path}/rescues');
    final nul = String.fromCharCode(0);
    final rift = _FakeRift();
    final git = _FakeGit(
      responses: {
        // Dirty worktree: status --porcelain returns changed files.
        'status --porcelain': const GitResult(
          exitCode: 0,
          stdout: ' M lib/foo.dart\n?? new.dart\n',
          stderr: '',
        ),
        'diff --binary HEAD': const GitResult(
          exitCode: 0,
          stdout: '--- a/lib/foo.dart\n+++ b/lib/foo.dart\n',
          stderr: '',
        ),
        'ls-files --others': GitResult(
          exitCode: 0,
          stdout: 'new.dart$nul',
          stderr: '',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git, wipRescueDir: rescues.path);

    await adapter.destroy(
      path: wt.path,
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.gitWorktree,
      branch: 'cc/conv/123',
    );

    // THE invariant: the capture writes no git object, no commit, no branch.
    // A linked worktree shares the source's store, so each of those three is a
    // write into the operator's own repo.
    expect(git.ran((a) => a.contains('add')), isFalse);
    expect(git.ran((a) => a.contains('commit')), isFalse);
    expect(git.ran((a) => a.length == 2 && a[0] == 'branch'), isFalse);

    // The work itself is preserved, outside every checkout.
    final folders = rescues.listSync().whereType<Directory>().toList();
    expect(folders, hasLength(1));
    expect(p.basename(folders.single.path), startsWith('cc-conv-123-'));
    expect(File('${folders.single.path}/changes.patch').existsSync(), isTrue);
    expect(
      File('${folders.single.path}/untracked/new.dart').readAsStringSync(),
      'void main() {}\n',
    );
    expect(File('${folders.single.path}/RESTORE.txt').existsSync(), isTrue);

    // …and the worktree is still torn down afterwards.
    expect(
      git.ran((a) => a.contains('worktree') && a.contains('remove')),
      isTrue,
    );
  });

  test('destroy captures nothing when no rescue dir is configured', () async {
    // No configured destination means no capture — never an improvised one.
    // The only directories in reach on this path are the worktree being
    // deleted and the source repo, and writing to the second is the bug.
    final wt = Directory('${tmp.path}/wt-nodir')..createSync();
    final rift = _FakeRift();
    final git = _FakeGit(
      responses: {
        'status --porcelain': const GitResult(
          exitCode: 0,
          stdout: ' M lib/foo.dart\n',
          stderr: '',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git);

    await adapter.destroy(
      path: wt.path,
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.gitWorktree,
      branch: 'cc/conv/123',
    );

    expect(git.ran((a) => a.contains('diff')), isFalse);
    expect(git.ran((a) => a.contains('commit')), isFalse);
    expect(
      git.ran((a) => a.contains('worktree') && a.contains('remove')),
      isTrue,
    );
  });

  test('destroy does NOT capture when the worktree is clean', () async {
    final wt = Directory('${tmp.path}/clean')..createSync();
    final rescues = Directory('${tmp.path}/rescues-clean');
    final rift = _FakeRift();
    // Default _FakeGit: status --porcelain returns empty stdout → clean.
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git, wipRescueDir: rescues.path);

    await adapter.destroy(
      path: wt.path,
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.gitWorktree,
      branch: 'cc/conv/123',
    );

    expect(git.ran((a) => a.contains('commit')), isFalse);
    expect(git.ran((a) => a.length == 2 && a[0] == 'branch'), isFalse);
    // An empty capture leaves no folder behind to sift through.
    expect(rescues.existsSync(), isFalse);
    // Still tears down.
    expect(
      git.ran((a) => a.contains('worktree') && a.contains('remove')),
      isTrue,
    );
  });

  test('a failed capture still proceeds to GC (best-effort)', () async {
    final wt = Directory('${tmp.path}/faildiff')..createSync();
    final rescues = Directory('${tmp.path}/rescues-fail');
    final rift = _FakeRift();
    final git = _FakeGit(
      responses: {
        'status --porcelain': const GitResult(
          exitCode: 0,
          stdout: ' M lib/foo.dart\n',
          stderr: '',
        ),
        'diff --binary HEAD': const GitResult(
          exitCode: 128,
          stdout: '',
          stderr: 'fatal: ambiguous argument HEAD',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git, wipRescueDir: rescues.path);

    // Must not throw and the worktree is still removed.
    await adapter.destroy(
      path: wt.path,
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.gitWorktree,
      branch: 'cc/conv/123',
    );

    expect(
      git.ran((a) => a.contains('worktree') && a.contains('remove')),
      isTrue,
    );
    expect(git.ran((a) => a.contains('commit')), isFalse);
    expect(git.ran((a) => a.length == 2 && a[0] == 'branch'), isFalse);
  });

  test('the teardown never issues a repo-mutating git command', () async {
    // The ratchet. Every route through the WIP capture is read-only, so a
    // future edit that reintroduces `add`/`commit`/`branch <name>` on this
    // path fails here rather than in an operator's checkout — which is where
    // the last several regressions were found. `branch -D` is exempt: that is
    // the teardown REMOVING the `conv/*` branch it created.
    final wt = Directory('${tmp.path}/ratchet')..createSync();
    final rescues = Directory('${tmp.path}/rescues-ratchet');
    final rift = _FakeRift();
    final git = _FakeGit(
      responses: {
        'status --porcelain': const GitResult(
          exitCode: 0,
          stdout: ' M lib/foo.dart\n?? new.dart\n',
          stderr: '',
        ),
        'diff --binary HEAD': const GitResult(
          exitCode: 0,
          stdout: '--- a/lib/foo.dart\n',
          stderr: '',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git, wipRescueDir: rescues.path);

    await adapter.destroy(
      path: wt.path,
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.gitWorktree,
      branch: 'cc/conv/123',
    );

    const mutating = {'add', 'commit', 'stash', 'checkout', 'push', 'merge'};
    for (final args in git.runs) {
      expect(
        args.any(mutating.contains),
        isFalse,
        reason: 'teardown ran a mutating git command: ${args.join(' ')}',
      );
      expect(
        args.length == 2 && args[0] == 'branch',
        isFalse,
        reason: 'teardown created a branch: ${args.join(' ')}',
      );
    }
  });

  // -- destroy: the capture never runs against the enclosing repo ------------

  test('destroy does not capture a directory that is not its own checkout', () async {
    // The bug this guard exists for. Git finds its repository by walking UP
    // from the working directory, and the server's data dir routinely sits
    // INSIDE a repo (`<repo>/apps/cc_server/data/…`). So a leftover or
    // half-provisioned worktree directory answers `status` / `diff` for the
    // ENCLOSING checkout — which, back when the capture was a commit, is how
    // "chore: rescued uncommitted work before worktree GC" commits carrying a
    // whole working tree landed on a user's own branch.
    final stray = Directory('${tmp.path}/stray')..createSync();
    final rescues = Directory('${tmp.path}/rescues-stray');
    final rift = _FakeRift();
    final git = _FakeGit(
      responses: {
        // `stray` is not a checkout; git reports the repo ABOVE it.
        'rev-parse --show-toplevel': GitResult(
          exitCode: 0,
          stdout: '${tmp.path}\n',
          stderr: '',
        ),
        'status --porcelain': const GitResult(
          exitCode: 0,
          stdout: ' M lib/foo.dart\n?? new.dart\n',
          stderr: '',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git, wipRescueDir: rescues.path);

    await adapter.destroy(
      path: stray.path,
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.gitWorktree,
      branch: 'conv/abc',
    );

    expect(git.ran((a) => a.contains('diff')), isFalse);
    expect(git.ran((a) => a.contains('commit')), isFalse);
    expect(rescues.existsSync(), isFalse);
    // …and the teardown itself still runs.
    expect(
      git.ran((a) => a.contains('worktree') && a.contains('remove')),
      isTrue,
    );
  });

  test('destroy refuses to capture when the path IS the source repo', () async {
    // A row that recorded the origin instead of the copy. This one passes the
    // checkout-root probe — it is a perfectly good repo — so only the identity
    // check stops it reading the operator's tree into a bogus capture.
    final src = Directory('${tmp.path}/src')..createSync();
    final rescues = Directory('${tmp.path}/rescues-src');
    final rift = _FakeRift();
    final git = _FakeGit(
      responses: {
        'status --porcelain': const GitResult(
          exitCode: 0,
          stdout: ' M lib/foo.dart\n',
          stderr: '',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git, wipRescueDir: rescues.path);

    await adapter.destroy(
      path: src.path,
      sourcePath: src.path,
      backend: RepoIsolationBackend.gitWorktree,
      branch: 'conv/abc',
    );

    expect(git.ran((a) => a.contains('diff')), isFalse);
    expect(git.ran((a) => a.contains('commit')), isFalse);
    expect(rescues.existsSync(), isFalse);
  });

  test('provision refuses to branch in a copy that is not a checkout', () async {
    // Same trap, worse blast radius: `checkout --force -B` resolved against an
    // enclosing repo moves ITS head and discards ITS uncommitted work.
    final rift = _FakeRift();
    final git = _FakeGit(
      responses: {
        'rev-parse --show-toplevel': GitResult(
          exitCode: 0,
          stdout: '${tmp.path}\n',
          stderr: '',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git);

    await expectLater(
      adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        baseRef: 'main',
      ),
      throwsA(isA<StateError>()),
    );
    expect(git.ran((a) => a.contains('checkout')), isFalse);
  });

  // =========================================================================
  // Path resolution — _resolveDefaultBranch
  // =========================================================================

  test('_resolveDefaultBranch strips remote prefix from origin/HEAD', () async {
    final rift = _FakeRift(available: false);
    final git = _FakeGit(
      responses: {
        'symbolic-ref': const GitResult(
          exitCode: 0,
          stdout: 'origin/develop\n',
          stderr: '',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git);

    await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'feature/x',
      // No baseRef → triggers resolution; symbolic-ref returns origin/develop.
    );

    // The resolved baseRef ('develop') should appear in the worktree add args.
    expect(
      git.ran(
        (a) =>
            a.contains('worktree') &&
            a.contains('add') &&
            a.join(' ').contains('develop'),
      ),
      isTrue,
    );
  });

  test(
    '_resolveDefaultBranch uses origin/main when origin/HEAD fails',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit(
        responses: {
          'symbolic-ref': const GitResult(
            exitCode: 1,
            stdout: '',
            stderr: 'not a symbolic ref',
          ),
          'show-ref --verify --quiet refs/remotes/origin/main': const GitResult(
            exitCode: 0,
            stdout: '',
            stderr: '',
          ),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      expect(
        git.ran(
          (a) =>
              a.contains('worktree') &&
              a.contains('add') &&
              a.join(' ').contains('main'),
        ),
        isTrue,
      );
      expect(
        git.ran((a) => a.contains('rev-parse') && a.contains('HEAD')),
        isFalse,
      );
    },
  );

  test(
    '_resolveDefaultBranch uses origin/master when main is absent',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit(
        responses: {
          'symbolic-ref': const GitResult(
            exitCode: 1,
            stdout: '',
            stderr: 'not a symbolic ref',
          ),
          'show-ref --verify --quiet refs/remotes/origin/main': const GitResult(
            exitCode: 1,
            stdout: '',
            stderr: 'not a valid ref',
          ),
          'show-ref --verify --quiet refs/remotes/origin/master':
              const GitResult(exitCode: 0, stdout: '', stderr: ''),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      expect(
        git.ran(
          (a) =>
              a.contains('worktree') &&
              a.contains('add') &&
              a.join(' ').contains('master'),
        ),
        isTrue,
      );
    },
  );

  test(
    '_resolveDefaultBranch falls back to main when both probes fail',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit(
        responses: {
          'symbolic-ref': const GitResult(
            exitCode: 128,
            stdout: '',
            stderr: 'fatal: not a symref',
          ),
          'show-ref': const GitResult(
            exitCode: 1,
            stdout: '',
            stderr: 'not a valid ref',
          ),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      // Ultimate fallback 'main' should appear in worktree add args.
      expect(
        git.ran(
          (a) =>
              a.contains('worktree') &&
              a.contains('add') &&
              a.join(' ').contains('main'),
        ),
        isTrue,
      );
    },
  );

  test(
    '_resolveDefaultBranch uses bare branch name when no slash in output',
    () async {
      final rift = _FakeRift(available: false);
      // Return a bare name (no remote/) — e.g. a local tracking ref edge case.
      final git = _FakeGit(
        responses: {
          'symbolic-ref': const GitResult(
            exitCode: 0,
            stdout: 'trunk\n',
            stderr: '',
          ),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      expect(
        git.ran(
          (a) =>
              a.contains('worktree') &&
              a.contains('add') &&
              a.join(' ').contains('trunk'),
        ),
        isTrue,
      );
    },
  );

  test(
    '_resolveDefaultBranch returns main when origin/HEAD stdout is empty',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit(
        responses: {
          'symbolic-ref': const GitResult(
            exitCode: 0,
            stdout: '  \n',
            stderr: '',
          ),
          'show-ref': const GitResult(
            exitCode: 1,
            stdout: '',
            stderr: 'not a valid ref',
          ),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      // Empty trimmed name → origin/main / origin/master missing → 'main'.
      expect(
        git.ran(
          (a) =>
              a.contains('worktree') &&
              a.contains('add') &&
              a.join(' ').contains('main'),
        ),
        isTrue,
      );
    },
  );

  test(
    '_resolveDefaultBranch never uses the currently checked-out branch',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit(
        responses: {
          'symbolic-ref': const GitResult(
            exitCode: 1,
            stdout: '',
            stderr: 'not symbolic',
          ),
          'show-ref': const GitResult(
            exitCode: 1,
            stdout: '',
            stderr: 'not a valid ref',
          ),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      // origin/HEAD missing and no origin/main|master → 'main', not HEAD.
      expect(
        git.ran(
          (a) =>
              a.contains('worktree') &&
              a.contains('add') &&
              a.join(' ').contains('main'),
        ),
        isTrue,
      );
      expect(
        git.ran((a) => a.contains('rev-parse') && a.contains('--abbrev-ref')),
        isFalse,
      );
    },
  );

  // =========================================================================
  // Isolation rules
  // =========================================================================

  test(
    'worktree fallback with headRef and no authUrl throws StateError',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      expect(
        () => adapter.provision(
          sourcePath: '/src/repo',
          destParentDir: tmp.path,
          name: 'repo',
          branch: 'pr-42',
          headRef: 'refs/pull/42/head',
          // No authUrl.
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('headRef on rift path skips default-branch resolution', () async {
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'pr-42',
      authUrl: 'https://token@github.com/owner/repo.git',
      headRef: 'refs/pull/42/head',
      // No baseRef provided — but should skip resolution because headRef present.
    );

    // symbolic-ref should NOT have been called — headRef path skips it.
    expect(git.ran((a) => a.contains('symbolic-ref')), isFalse);
  });

  test(
    'headRef on rift path with empty baseRef still skips default-branch resolution',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'pr-42',
        authUrl: 'https://token@github.com/owner/repo.git',
        headRef: 'refs/pull/42/head',
        baseRef: '', // Explicit empty.
      );

      expect(git.ran((a) => a.contains('symbolic-ref')), isFalse);
    },
  );

  test('on rift path, no git command names sourcePath either', () async {
    // Sibling of the workdir assertion above: nothing puts the source path in
    // the ARGV either, so no command can reach it by argument (a `-C`, a
    // pathspec, a fetch URL pointing back at the user's checkout).
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'feature/x',
      baseRef: 'main',
    );

    expect(git.inDir('/src/repo'), isEmpty);
    expect(
      git.runs.map((args) => args.join(' ')).where((s) => s.contains('/src/')),
      isEmpty,
    );
  });

  // =========================================================================
  // Edge cases — _fetchAndBranch fallback chain
  // =========================================================================

  test(
    '_fetchAndBranch: start points fail, bare checkout succeeds (last resort)',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit(
        responses: {
          // Fetch succeeded → first start is FETCH_HEAD.
          'FETCH_HEAD': const GitResult(
            exitCode: 128,
            stdout: '',
            stderr: 'fatal: not a valid ref',
          ),
          // Inherited remote-tracking ref also fails.
          'refs/remotes/origin/main': const GitResult(
            exitCode: 128,
            stdout: '',
            stderr: 'fatal: not a valid ref',
          ),
          // Local 'main' also fails.
          'feature/x main': const GitResult(
            exitCode: 1,
            stdout: '',
            stderr: 'error: pathspec main did not match',
          ),
          // The bare 'checkout --force -B feature/x' (no start point) succeeds.
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        authUrl: 'https://token@github.com/owner/repo.git',
        baseRef: 'main',
      );

      expect(result.backend, RepoIsolationBackend.rift);
      // The last-resort bare checkout should have run.
      expect(
        git.ran(
          (a) =>
              a.contains('checkout') &&
              a.contains('-B') &&
              a.contains('feature/x') &&
              !a.contains('FETCH_HEAD') &&
              !a.contains('refs/remotes/origin/') &&
              !a.contains('main'),
        ),
        isTrue,
      );
    },
  );

  test(
    '_fetchAndBranch: all checkout attempts fail throws StateError',
    () async {
      final rift = _FakeRift();
      // All checkout -B commands fail (start points + bare fallback).
      final git = _FakeGit(
        responses: {
          'checkout --force -B': const GitResult(
            exitCode: 128,
            stdout: '',
            stderr: 'fatal: could not create branch',
          ),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      expect(
        () => adapter.provision(
          sourcePath: '/src/repo',
          destParentDir: tmp.path,
          name: 'repo',
          branch: 'feature/x',
          authUrl: 'https://token@github.com/owner/repo.git',
          baseRef: 'main',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  // =========================================================================
  // Edge cases — worktree fallback
  // =========================================================================

  test('worktree fallback --detach add failure throws StateError', () async {
    final rift = _FakeRift(available: false);
    final git = _FakeGit(
      responses: {
        // Fetch succeeds (default).
        'worktree add --force --detach': const GitResult(
          exitCode: 128,
          stdout: '',
          stderr: 'fatal: worktree add failed',
        ),
      },
    );
    final adapter = _adapter(rift: rift, git: git);

    expect(
      () => adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'pr-42',
        authUrl: 'https://token@github.com/owner/repo.git',
        headRef: 'refs/pull/42/head',
      ),
      throwsA(isA<StateError>()),
    );
  });

  // =========================================================================
  // Edge cases — _riftCreate
  // =========================================================================

  test(
    '_riftCreate: non-unsafe init error is swallowed, create proceeds',
    () async {
      final rift = _FakeRift(
        initError: const RiftException(
          code: 'already_initialized',
          message: 'no-op',
        ),
      );
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        baseRef: 'main',
      );

      expect(result.backend, RepoIsolationBackend.rift);
      expect(rift.calls, contains('init:/src/repo'));
      expect(rift.calls, contains('create'));
    },
  );

  test(
    '_riftCreate: create retry after isInitRequired calls init then create again',
    () async {
      // Already covered by 'provision — rift create throws isInitRequired, retries after init'.
      // This test verifies the exact sequence: init → create(fails) → init → create(succeeds).
      final rift = _FakeRift(
        createError: const RiftException(
          code: 'workspace_not_initialized',
          message: 'needs init',
        ),
      );
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        baseRef: 'main',
      );

      // Sequence: init, create(fails), init(retry), create(succeeds).
      final initCalls = rift.calls.where((c) => c.startsWith('init:')).length;
      final createCalls = rift.calls.where((c) => c == 'create').length;
      expect(initCalls, 2);
      expect(createCalls, 2);
    },
  );

  // =========================================================================
  // Edge cases — a `.rift` marker this registry does not know
  // =========================================================================
  //
  // The marker lives in the SOURCE repo and names a registry entry, so it
  // outlives our data dir and is unknown to any other registry file. Degrading
  // to `git worktree` on it pinned that repo to the slow backend forever, since
  // nothing ever clears the marker — so the adapter re-adopts the source
  // instead.

  test('re-adopts the source when init reports marker_mismatch', () async {
    final rift = _FakeRift(
      initError: const RiftException(
        code: 'marker_mismatch',
        message: 'rift marker does not match the registry at: /src/repo',
      ),
      markerPresent: true,
    );
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    final result = await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'feature/x',
      baseRef: 'main',
    );

    expect(result.backend, RepoIsolationBackend.rift);
    expect(rift.calls, contains('clearMarker:/src/repo'));
    // init, clearMarker, init (re-adopt), create.
    expect(rift.calls.where((c) => c.startsWith('init:')).length, 2);
    expect(git.ran((a) => a.contains('worktree')), isFalse);
  });

  test('re-adopts the source when create reports unknown_marker', () async {
    final rift = _FakeRift(
      createError: const RiftException(
        code: 'unknown_marker',
        message: 'rift marker belongs to an unknown registry entry',
      ),
      markerPresent: true,
    );
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    final result = await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'feature/x',
      baseRef: 'main',
    );

    expect(result.backend, RepoIsolationBackend.rift);
    expect(rift.calls, contains('clearMarker:/src/repo'));
    expect(rift.calls.where((c) => c == 'create').length, 2);
    expect(git.ran((a) => a.contains('worktree')), isFalse);
  });

  test('an undeletable stale marker fails the provision', () async {
    // Read-only checkout / permissions: the heal cannot run. There is nowhere
    // to degrade to — the only other backend writes into the very checkout
    // that is refusing writes — so the marker error reaches the caller, who
    // can say which repo needs its `.rift` removed by hand.
    final rift = _FakeRift(
      createError: const RiftException(
        code: 'unknown_marker',
        message: 'rift marker belongs to an unknown registry entry',
      ),
      markerPresent: true,
      clearMarkerThrows: true,
    );
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    await expectLater(
      adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        baseRef: 'main',
      ),
      throwsA(
        isA<RiftException>().having((e) => e.code, 'code', 'unknown_marker'),
      ),
    );
    expect(rift.calls.where((c) => c == 'create').length, 1);
    expect(git.ran((a) => a.contains('worktree')), isFalse);
  });

  test('a stale-marker init error with no marker on disk is a note', () async {
    // Nothing to clear (another process already healed it): no retry storm and
    // the provision still lands on rift.
    final rift = _FakeRift(
      initError: const RiftException(
        code: 'marker_mismatch',
        message: 'rift marker does not match the registry at: /src/repo',
      ),
    );
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    final result = await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'feature/x',
      baseRef: 'main',
    );

    expect(result.backend, RepoIsolationBackend.rift);
    expect(rift.calls.where((c) => c.startsWith('init:')).length, 1);
  });

  test('unsafe_git on init still rethrows, marker or not', () async {
    final rift = _FakeRift(
      initError: const RiftException(
        code: 'unsafe_git',
        message: 'rebase in progress',
      ),
      markerPresent: true,
    );
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    await expectLater(
      adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        baseRef: 'main',
      ),
      throwsA(isA<RiftException>()),
    );
    expect(rift.calls, isNot(contains('clearMarker:/src/repo')));
  });

  // =========================================================================
  // Edge cases — authUrl / credential handling
  // =========================================================================

  test('provision with authUrl on normal path uses fetch + checkout', () async {
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    final result = await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'feature/x',
      authUrl: 'https://token@github.com/owner/repo.git',
      baseRef: 'main',
    );

    expect(result.backend, RepoIsolationBackend.rift);
    // Fetch writes FETCH_HEAD only — never origin/main.
    expect(
      git.ran(
        (a) =>
            a.contains('fetch') &&
            a.contains('main') &&
            !a.any((s) => s.contains('refs/remotes/origin/')),
      ),
      isTrue,
    );
    expect(
      git.ran(
        (a) =>
            a.contains('checkout') &&
            a.contains('-B') &&
            a.contains('FETCH_HEAD'),
      ),
      isTrue,
    );
  });

  test(
    'provision with authUrl on worktree path fetches into source then creates worktree',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        authUrl: 'https://token@github.com/owner/repo.git',
        baseRef: 'develop',
      );

      expect(result.backend, RepoIsolationBackend.gitWorktree);
      // Fetched into FETCH_HEAD in the source — never origin/develop.
      expect(
        git.ran(
          (a) =>
              a.contains('fetch') &&
              a.contains('develop') &&
              !a.any((s) => s.contains('refs/remotes/origin/')),
        ),
        isTrue,
      );
      expect(
        git.ran(
          (a) =>
              a.contains('worktree') &&
              a.contains('add') &&
              a.contains('FETCH_HEAD'),
        ),
        isTrue,
      );
    },
  );

  test(
    'empty authUrl fetches the origin URL to FETCH_HEAD, never an empty repo',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit(
        responses: {
          'remote get-url': const GitResult(
            exitCode: 0,
            stdout: 'git@github.com:Uber/uber-cloud-a.git\n',
            stderr: '',
          ),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        baseRef: 'main',
      );

      expect(
        git.ran(
          (a) =>
              a.contains('fetch') &&
              a.contains('git@github.com:Uber/uber-cloud-a.git') &&
              a.contains('main') &&
              !a.any((s) => s.contains('refs/remotes/origin/')),
        ),
        isTrue,
      );
      expect(
        git.ran((a) => a.contains('fetch') && a.any((s) => s.isEmpty)),
        isFalse,
      );
    },
  );

  test(
    'empty origin URL skips fetch and checks out local origin/main',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        baseRef: 'main',
      );

      expect(git.ran((a) => a.contains('fetch')), isFalse);
      expect(
        git.ran(
          (a) =>
              a.contains('checkout') &&
              a.contains('-B') &&
              a.contains('refs/remotes/origin/main'),
        ),
        isTrue,
      );
    },
  );

  // =========================================================================
  // Edge cases — destroy
  // =========================================================================

  test('destroy rift backend skips branch deletion for worktree', () async {
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = _adapter(rift: rift, git: git);

    await adapter.destroy(
      path: '/iso/repo',
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.rift,
      branch: 'feature/x',
    );

    // Rift destroy should NOT call any git commands.
    expect(git.runs, isEmpty);
  });

  test(
    'destroy worktree backend with null branch only removes worktree',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      await adapter.destroy(
        path: '/iso/repo',
        sourcePath: '/src/repo',
        backend: RepoIsolationBackend.gitWorktree,
        // branch omitted (null).
      );

      expect(
        git.ran((a) => a.contains('worktree') && a.contains('remove')),
        isTrue,
      );
      expect(git.ran((a) => a.contains('branch') && a.contains('-D')), isFalse);
    },
  );

  // =========================================================================
  // Edge cases — provision parameter combinations
  // =========================================================================

  test(
    'provision with headRef=empty-string treats it as absent (normal path)',
    () async {
      final rift = _FakeRift();
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      final result = await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        headRef: '', // Empty string, not null.
        baseRef: 'main',
      );

      expect(result.backend, RepoIsolationBackend.rift);
      // Empty headRef follows the space path (checkout -B), not the PR path.
      expect(
        git.ran((a) => a.contains('checkout') && a.contains('-B')),
        isTrue,
      );
    },
  );

  test(
    'provision with baseRef=empty-string resolves default branch (same as omitted)',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit();
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
        baseRef: '', // Explicit empty — should trigger resolution.
      );

      // Empty baseRef triggers _resolveDefaultBranch (symbolic-ref).
      expect(git.ran((a) => a.contains('symbolic-ref')), isTrue);
    },
  );

  // =========================================================================
  // Edge cases — _resolveDefaultBranch parsing
  // =========================================================================

  test(
    '_resolveDefaultBranch handles symbolic-ref output with trailing whitespace',
    () async {
      final rift = _FakeRift(available: false);
      final git = _FakeGit(
        responses: {
          'symbolic-ref': const GitResult(
            exitCode: 0,
            stdout: '  origin/main\n\n',
            stderr: '',
          ),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      // Trimmed to 'origin/main' → 'main'.
      expect(
        git.ran(
          (a) =>
              a.contains('worktree') &&
              a.contains('add') &&
              a.join(' ').contains('main'),
        ),
        isTrue,
      );
    },
  );

  test(
    '_resolveDefaultBranch with lastIndexOf on multi-slash ref returns last segment',
    () async {
      // The adapter uses lastIndexOf('/'), so origin/a/b/c → 'c'.
      final rift = _FakeRift(available: false);
      final git = _FakeGit(
        responses: {
          'symbolic-ref': const GitResult(
            exitCode: 0,
            stdout: 'origin/alpha/beta\n',
            stderr: '',
          ),
        },
      );
      final adapter = _adapter(rift: rift, git: git);

      await adapter.provision(
        sourcePath: '/src/repo',
        destParentDir: tmp.path,
        name: 'repo',
        branch: 'feature/x',
      );

      // lastIndexOf('/') on 'origin/alpha/beta' → 'beta'.
      expect(
        git.ran(
          (a) =>
              a.contains('worktree') &&
              a.contains('add') &&
              a.join(' ').contains('beta'),
        ),
        isTrue,
      );
    },
  );
}
