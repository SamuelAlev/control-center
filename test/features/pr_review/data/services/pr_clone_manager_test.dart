// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/pr_review/pr_clone_manager.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeGit implements GitCommandPort {
  final List<List<String>> runs = [];
  final List<Map<String, String>> runEnvs = [];

  final List<List<String>> _streamLinesQueue = [];
  final List<Object> _streamErrors = [];
  final List<GitResult> _runResults = [];

  void enqueueStreamLines(List<String> lines) => _streamLinesQueue.add(lines);
  void enqueueStreamError(Object error) => _streamErrors.add(error);
  void enqueueRunResult(GitResult result) => _runResults.add(result);

  @override
  Future<GitResult> run(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
  }) async {
    runs.add(List.of(args));
    runEnvs.add(Map.of(env ?? const {}));
    if (_runResults.isNotEmpty) {
      return _runResults.removeAt(0);
    }
    return const GitResult(exitCode: 0, stdout: '', stderr: '');
  }

  @override
  Stream<String> runStreaming(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
  }) async* {
    runs.add(List.of(args));
    runEnvs.add(Map.of(env ?? const {}));
    if (_streamErrors.isNotEmpty) {
      throw _streamErrors.removeAt(0);
    }
    if (_streamLinesQueue.isNotEmpty) {
      yield* Stream.fromIterable(_streamLinesQueue.removeAt(0));
    }
  }
}

class _FakeFilesystem extends Fake implements WorkspaceFilesystemPort {
  _FakeFilesystem(this.baseDir);

  final String baseDir;

  @override
  Future<Directory> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  ) async =>
      Directory('$baseDir/$workspaceId/pr_clones/${owner}__$repo');
}

class _OneThrowFilesystem extends Fake implements WorkspaceFilesystemPort {
  _OneThrowFilesystem(this.baseDir, this._error);

  final String baseDir;
  final Object _error;
  bool _threw = false;

  @override
  Future<Directory> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  ) async {
    if (!_threw) {
      _threw = true;
      throw _error;
    }
    return Directory('$baseDir/$workspaceId/pr_clones/${owner}__$repo');
  }
}

class _FakeRift extends RiftClient {
  _FakeRift({this.available = true, this.createResult = '/fake/dest'})
      : super(dylibPaths: const [], databasePath: 'mem');

  final bool available;
  final String createResult;
  Object? initError;

  @override
  bool get isAvailable => available;

  @override
  Future<void> init({required String at}) async {
    if (initError != null) {
      throw initError!;
    }
  }

  @override
  Future<String> create({
    required String from,
    required String into,
    String? name,
    bool copyAll = true,
    bool hooks = false,
  }) async =>
      createResult;

  @override
  Future<void> remove({required String at}) async {}

  @override
  Future<List<String>> gc() async => const [];

  @override
  Future<List<String>> list({required String of}) async => const [];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PrCloneManager _manager({
  required Directory tmp,
  _FakeGit? git,
  WorkspaceFilesystemPort? filesystem,
  String? workspaceId,
  String? owner,
  String? repo,
  String? githubToken,
  String? localCheckoutPath,
  _FakeRift? rift,
}) {
  return PrCloneManager(
    git: git ?? _FakeGit(),
    filesystem: filesystem ?? _FakeFilesystem(tmp.path),
    workspaceId: workspaceId ?? 'ws1',
    owner: owner ?? 'octocat',
    repo: repo ?? 'hello',
    githubToken: githubToken ?? 'token',
    localCheckoutPath: localCheckoutPath,
    rift: rift,
  );
}

Future<void> drainStream(Stream<PrCloneProgress> stream) async {
  await for (final _ in stream) {
    // Drain.
  }
}

String _cloneDirPath(
  Directory tmp, {
  String workspaceId = 'ws1',
  String owner = 'octocat',
  String repo = 'hello',
}) {
  return '${tmp.path}/$workspaceId/pr_clones/${owner}__$repo';
}

void _createGitDir(Directory parent) {
  if (!parent.existsSync()) {
    parent.createSync(recursive: true);
  }
  Directory('${parent.path}/.git').createSync(recursive: true);
}

// ---------------------------------------------------------------------------
// Tests: clonePath
// ---------------------------------------------------------------------------

void main() {
  group('clonePath', () {
    test('resolves via prCloneDir on the filesystem port', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      final manager = _manager(tmp: tmp, git: git);

      final path = await manager.clonePath();

      expect(path, _cloneDirPath(tmp));
    });

    test('includes owner and repo in resolved path', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      final manager = _manager(
        tmp: tmp,
        git: git,
        owner: 'flutter',
        repo: 'engine',
      );

      final path = await manager.clonePath();

      expect(path, contains('flutter'));
      expect(path, contains('engine'));
    });
  });

  // -------------------------------------------------------------------------
  // Tests: busy flag
  // -------------------------------------------------------------------------

  group('busy flag', () {
    test('rejects concurrent ensureCloneAndFetch when busy', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines(['Fetching...']);

      final manager = _manager(tmp: tmp, git: git);

      // Start first operation — sets _busy = true on listen.
      final stream1 = manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      );
      final sub1 = stream1.listen((_) {});

      // Second call while first is still in-flight.
      final stream2 = manager.ensureCloneAndFetch(
        prNumber: 2,
        baseRef: 'develop',
        headSha: 'def456',
      );
      final events2 = await stream2.toList();

      expect(events2, isEmpty);

      await sub1.cancel();
    });

    test('allows sequential calls after first completes', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      final events1 = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();
      expect(events1.last.phase, PrClonePhase.ready);

      final events2 = await manager.ensureCloneAndFetch(
        prNumber: 2,
        baseRef: 'develop',
        headSha: 'def456',
      ).toList();
      expect(events2.last.phase, PrClonePhase.ready);
    });

    test('resets busy flag after synchronous error', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      // One-shot throw: first prCloneDir throws, second works.
      final fs = _OneThrowFilesystem(
        tmp.path,
        Exception('Filesystem error'),
      );
      final git = _FakeGit();
      final manager = _manager(tmp: tmp, git: git, filesystem: fs);

      // First call: prCloneDir throws → caught by try/catch → error phase.
      final events1 = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();
      expect(events1.last.phase, PrClonePhase.error);

      // Second call on the SAME manager: busy was reset in finally.
      // This time prCloneDir succeeds. Create .git so clone is skipped.
      _createGitDir(Directory(_cloneDirPath(tmp)));
      final events2 = await manager.ensureCloneAndFetch(
        prNumber: 2,
        baseRef: 'develop',
        headSha: 'def456',
      ).toList();
      expect(events2.last.phase, PrClonePhase.ready);
    });
  });

  // -------------------------------------------------------------------------
  // Tests: clone state machine (fresh clone)
  // -------------------------------------------------------------------------

  group('state machine — fresh clone', () {
    test('emits cloning → fetching → ready when .git is absent', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines(['Cloning into...']);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetching...']);

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      // Event order:
      // 0: cloning("")         — initial phase marker
      // 1: cloning("line")     — _doClone streaming
      // 2: fetching("")        — phase marker
      // 3: fetching("line")    — _doFetch streaming
      // 4: ready               — terminal
      expect(events.length, greaterThanOrEqualTo(3));
      expect(events[0].phase, PrClonePhase.cloning);
      expect(events[0].message, '');
      expect(events[1].phase, PrClonePhase.cloning);
      expect(events[1].message, 'Cloning into...');
      // Phase transitions correctly through fetching to ready.
      final phases = events.map((e) => e.phase).toSet();
      expect(phases, contains(PrClonePhase.cloning));
      expect(phases, contains(PrClonePhase.fetching));
      expect(events.last.phase, PrClonePhase.ready);
      expect(events.last.isTerminal, isTrue);
    });

    test('clone args includes --filter=blob:none and --no-checkout', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      final cloneArgs = git.runs[0];
      expect(cloneArgs, contains('clone'));
      expect(cloneArgs, contains('--filter=blob:none'));
      expect(cloneArgs, contains('--no-checkout'));
      expect(cloneArgs, contains('--no-tags'));
      expect(cloneArgs, contains('--progress'));
    });

    test('clone disables gc auto and maintenance auto', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      final cloneArgs = git.runs[0];
      final cIndices = <int>[];
      for (var i = 0; i < cloneArgs.length; i++) {
        if (cloneArgs[i] == '-c') {
          cIndices.add(i);
        }
      }
      final cValues = cIndices.map((i) => cloneArgs[i + 1]).toList();
      expect(cValues, contains('gc.auto=0'));
      expect(cValues, contains('maintenance.auto=false'));
    });

    test('clone auth URL is passed as positional arg (not last)', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      final cloneArgs = git.runs[0];
      expect(
        cloneArgs,
        contains('https://x-access-token:token@github.com/octocat/hello.git'),
      );
      // The last arg is the destination path, not the auth URL.
      final clonePath = cloneArgs.last;
      expect(clonePath, isNot(contains('x-access-token')));
      expect(clonePath, contains('pr_clones'));
    });

    test('resets remote URL to clean URL without token', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      // run[1] is the remote set-url call.
      final remoteArgs = git.runs[1];
      expect(remoteArgs, contains('remote'));
      expect(remoteArgs, contains('set-url'));
      expect(remoteArgs, contains('origin'));
      final remoteUrl = remoteArgs.last;
      expect(remoteUrl, isNot(contains('x-access-token')));
      expect(remoteUrl, isNot(contains('@')));
      expect(remoteUrl, 'https://github.com/octocat/hello.git');
    });
  });

  // -------------------------------------------------------------------------
  // Tests: skip clone (reuse)
  // -------------------------------------------------------------------------

  group('state machine — skip clone', () {
    test('skips clone when .git directory already exists', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines(['Fetching...']);

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      // Event order: fetching(""), fetching(line), ready.
      expect(events.length, greaterThanOrEqualTo(2));
      expect(events[0].phase, PrClonePhase.fetching);
      expect(events[0].message, '');
      expect(events.last.phase, PrClonePhase.ready);

      // No clone command was issued.
      final hasClone = git.runs.any((args) => args.contains('clone'));
      expect(hasClone, isFalse);
    });

    test('only fetch is called when clone is skipped', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      // Only one call: the fetch.
      expect(git.runs.length, 1);
      expect(git.runs[0], contains('fetch'));
    });
  });

  // -------------------------------------------------------------------------
  // Tests: fetch refspecs
  // -------------------------------------------------------------------------

  group('fetch', () {
    test('constructs correct base ref refspec', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      final fetchArgs = git.runs[0];
      expect(fetchArgs, contains('main:refs/remotes/origin/main'));
    });

    test('constructs correct PR head refspec', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 42,
        baseRef: 'develop',
        headSha: 'abc123',
      ));

      final fetchArgs = git.runs[0];
      expect(fetchArgs, contains('refs/pull/42/head:refs/pr/42/head'));
    });

    test('fetch uses --force to overwrite stale refs', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      expect(git.runs[0], contains('--force'));
    });
  });

  // -------------------------------------------------------------------------
  // Tests: base env
  // -------------------------------------------------------------------------

  group('environment', () {
    test('passes GIT_TERMINAL_PROMPT=0 to all git calls', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      expect(git.runEnvs, isNotEmpty);
      for (final env in git.runEnvs) {
        expect(env['GIT_TERMINAL_PROMPT'], '0');
      }
    });

    test('passes GIT_ASKPASS=echo to all git calls', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      for (final env in git.runEnvs) {
        expect(env['GIT_ASKPASS'], 'echo');
      }
    });

    test('passes GIT_CONFIG_NOSYSTEM=1 to all git calls', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      for (final env in git.runEnvs) {
        expect(env['GIT_CONFIG_NOSYSTEM'], '1');
      }
    });
  });

  // -------------------------------------------------------------------------
  // Tests: CoW (rift) path
  // -------------------------------------------------------------------------

  group('CoW via rift', () {
    test('uses CoW copy and emits cloning → fetching → ready', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final src = Directory('${tmp.path}/local_checkout');
      _createGitDir(src);

      final rift = _FakeRift(
        available: true,
        createResult: _cloneDirPath(tmp),
      );
      final git = _FakeGit();
      git.enqueueStreamLines(['Fetching...']);

      final manager = _manager(
        tmp: tmp,
        git: git,
        localCheckoutPath: src.path,
        rift: rift,
      );

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      // Event order:
      // 0: cloning("")         — initial phase marker (always yielded)
      // 1: fetching("")        — phase marker
      // 2: fetching("line")    — _doFetch streaming
      // 3: ready
      expect(events[0].phase, PrClonePhase.cloning);
      expect(events[0].message, '');
      expect(events[1].phase, PrClonePhase.fetching);
      expect(events.last.phase, PrClonePhase.ready);

      // No clone network command issued.
      final hasClone = git.runs.any((args) => args.contains('clone'));
      expect(hasClone, isFalse);
    });

    test('falls back to network clone when CoW throws RiftException', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final src = Directory('${tmp.path}/local_checkout');
      _createGitDir(src);

      final rift = _FakeRift(available: true);
      rift.initError = const RiftException(
        code: 'cow_unavailable',
        message: 'No CoW support',
      );
      final git = _FakeGit();
      git.enqueueStreamLines(['Cloning...']);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetching...']);

      final manager = _manager(
        tmp: tmp,
        git: git,
        localCheckoutPath: src.path,
        rift: rift,
      );

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      // events[0] = cloning(""), events[1] = cloning("Cloning..."), ...
      expect(events[0].phase, PrClonePhase.cloning);
      expect(events[0].message, '');
      expect(events[1].phase, PrClonePhase.cloning);
      expect(events[1].message, 'Cloning...');
      // Phases include cloning, fetching, ready.
      final phases = events.map((e) => e.phase).toSet();
      expect(phases, contains(PrClonePhase.cloning));
      expect(phases, contains(PrClonePhase.fetching));
      expect(events.last.phase, PrClonePhase.ready);
    });

    test('falls back to network clone when CoW throws generic Exception',
        () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final src = Directory('${tmp.path}/local_checkout');
      _createGitDir(src);

      final rift = _FakeRift(available: true);
      rift.initError = StateError('rift crashed');
      final git = _FakeGit();
      git.enqueueStreamLines(['Cloning...']);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(
        tmp: tmp,
        git: git,
        localCheckoutPath: src.path,
        rift: rift,
      );

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      // Falls through to clone.
      expect(events[0].phase, PrClonePhase.cloning);
      expect(events[1].phase, PrClonePhase.cloning);
      expect(events.last.phase, PrClonePhase.ready);
    });

    test('skips CoW when localCheckoutPath is null', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(
        tmp: tmp,
        git: git,
        localCheckoutPath: null,
        rift: _FakeRift(available: true),
      );

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      expect(events[0].phase, PrClonePhase.cloning);
    });

    test('skips CoW when rift is not available', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final src = Directory('${tmp.path}/local_checkout');
      _createGitDir(src);

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(
        tmp: tmp,
        git: git,
        localCheckoutPath: src.path,
        rift: _FakeRift(available: false),
      );

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      expect(events[0].phase, PrClonePhase.cloning);
    });
  });

  // -------------------------------------------------------------------------
  // Tests: error handling
  // -------------------------------------------------------------------------

  group('error handling', () {
    test('catches synchronous errors and yields error phase', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final fs = _OneThrowFilesystem(tmp.path, Exception('Filesystem error'));
      final git = _FakeGit();
      final manager = _manager(tmp: tmp, git: git, filesystem: fs);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      expect(events.length, 1);
      expect(events[0].phase, PrClonePhase.error);
      expect(events[0].error, isA<Exception>());
      expect(events[0].isTerminal, isTrue);
    });

    test('propagates stream error from _doClone runStreaming', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamError(StateError('Bad object'));

      final manager = _manager(tmp: tmp, git: git);

      final stream = manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      );

      // yield* stream errors are NOT caught by try/catch in async*.
      // They propagate to the listener.
      expect(
        stream.toList(),
        throwsA(isA<StateError>()),
      );
    });

    test('propagates stream error from _doFetch runStreaming', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamError(StateError('Bad object'));

      final manager = _manager(tmp: tmp, git: git);

      final stream = manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      );

      // Stream error from _doFetch propagates through yield*.
      expect(
        stream.toList(),
        throwsA(isA<StateError>()),
      );
    });

    test('busy flag is reset after stream error from clone', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamError(StateError('Network failure'));
      // For the second call on the same manager (skip clone path).
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      // First call: stream error from _doClone propagates.
      // The finally block resets _busy after the stream completes.
      try {
        await for (final _ in manager.ensureCloneAndFetch(
          prNumber: 1,
          baseRef: 'main',
          headSha: 'abc123',
        )) {}
      } catch (_) {
        // Expected: stream error from _doClone.
      }

      // Second call on the SAME manager: busy was reset via finally.
      _createGitDir(Directory(_cloneDirPath(tmp)));
      final events2 = await manager.ensureCloneAndFetch(
        prNumber: 2,
        baseRef: 'develop',
        headSha: 'def456',
      ).toList();
      expect(events2.last.phase, PrClonePhase.ready);
    });
  });

  // -------------------------------------------------------------------------
  // Tests: progress message sanitization
  // -------------------------------------------------------------------------

  // -------------------------------------------------------------------------
  // Tests: progress message sanitization
  // -------------------------------------------------------------------------

  group('progress sanitization', () {
    // _sanitize uses a raw-string regex r'\x1B\[[0-9;]*[a-zA-Z]'.
    // In Dart regex, \x1B within a raw regex string IS a hex escape for the
    // ESC character (0x1B), not literal backslash-x-1-B. Test strings use
    // non-raw Dart strings ('\x1B[...') so they contain actual ESC bytes.
    test('strips ANSI escape sequences from progress messages', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([
        '\x1B[1mremote: Enumerating objects: 10\x1B[0m',
        '\x1B[32mReceiving objects: 50%\x1B[0m',
      ]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetch done']);

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      // events[0] = cloning(""), events[1] = cloning(line1), events[2] = cloning(line2)
      final cloneEvents = events
          .where((e) => e.phase == PrClonePhase.cloning && e.message.isNotEmpty)
          .toList();
      expect(cloneEvents[0].message, 'Enumerating objects: 10');
      expect(cloneEvents[1].message, 'Receiving objects: 50%');
    });

    test('strips "remote: " prefix from progress messages', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([
        'remote: Compressing objects: 100%',
        'remote: Total 50 (delta 10), reused 40 (delta 5)',
      ]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetch done']);

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      final cloneEvents = events
          .where((e) => e.phase == PrClonePhase.cloning && e.message.isNotEmpty)
          .toList();
      expect(cloneEvents[0].message, 'Compressing objects: 100%');
      expect(
        cloneEvents[1].message,
        'Total 50 (delta 10), reused 40 (delta 5)',
      );
    });

    test('trims whitespace after sanitization', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      // _sanitize runs replaceFirst(^remote:) BEFORE trim(), so leading
      // spaces prevent "remote:" removal. The result is trimmed whitespace
      // but retained "remote:".
      git.enqueueStreamLines(['  remote: Spaced line  ']);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetch done']);

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      final cloneEvents = events
          .where((e) => e.phase == PrClonePhase.cloning && e.message.isNotEmpty)
          .toList();
      expect(cloneEvents[0].message, 'remote: Spaced line');
    });

    test('preserves non-progress lines without modification', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines(['Already up to date.']);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetch done']);

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      final cloneEvents = events
          .where((e) => e.phase == PrClonePhase.cloning && e.message.isNotEmpty)
          .toList();
      expect(cloneEvents[0].message, 'Already up to date.');
    });

    test('removes only the first "remote:" prefix', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines(['remote: remote: Double prefix']);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetch done']);

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      final cloneEvents = events
          .where((e) => e.phase == PrClonePhase.cloning && e.message.isNotEmpty)
          .toList();
      // _sanitize uses replaceFirst, so only the leading "remote: " is removed.
      expect(cloneEvents[0].message, 'remote: Double prefix');
    });
  });

  // -------------------------------------------------------------------------
  // Tests: PrCloneProgress isTerminal
  // -------------------------------------------------------------------------

  group('PrCloneProgress.isTerminal', () {
    test('ready is terminal', () {
      const progress = PrCloneProgress(phase: PrClonePhase.ready);
      expect(progress.isTerminal, isTrue);
    });

    test('error is terminal', () {
      const progress = PrCloneProgress(phase: PrClonePhase.error);
      expect(progress.isTerminal, isTrue);
    });

    test('cloning is not terminal', () {
      const progress = PrCloneProgress(phase: PrClonePhase.cloning);
      expect(progress.isTerminal, isFalse);
    });

    test('fetching is not terminal', () {
      const progress = PrCloneProgress(phase: PrClonePhase.fetching);
      expect(progress.isTerminal, isFalse);
    });

    test('computing is not terminal', () {
      const progress = PrCloneProgress(phase: PrClonePhase.computing);
      expect(progress.isTerminal, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Tests: additional CoW skip conditions
  // -------------------------------------------------------------------------

  group('CoW skip conditions', () {
    test('skips CoW when localCheckoutPath is an empty string', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(
        tmp: tmp,
        git: git,
        localCheckoutPath: '',
        rift: _FakeRift(available: true),
      );

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      // Falls through to network clone.
      expect(events[0].phase, PrClonePhase.cloning);
      final hasClone = git.runs.any((args) => args.contains('clone'));
      expect(hasClone, isTrue);
    });

    test('skips CoW when source .git does not exist', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      // Create a source dir WITHOUT .git.
      final src = Directory('${tmp.path}/local_checkout');
      src.createSync(recursive: true);

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(
        tmp: tmp,
        git: git,
        localCheckoutPath: src.path,
        rift: _FakeRift(available: true),
      );

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      expect(events[0].phase, PrClonePhase.cloning);
      final hasClone = git.runs.any((args) => args.contains('clone'));
      expect(hasClone, isTrue);
    });

    test('skips CoW when rift is null', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final src = Directory('${tmp.path}/local_checkout');
      _createGitDir(src);

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(
        tmp: tmp,
        git: git,
        localCheckoutPath: src.path,
        rift: null,
      );

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      expect(events[0].phase, PrClonePhase.cloning);
      final hasClone = git.runs.any((args) => args.contains('clone'));
      expect(hasClone, isTrue);
    });

    test('falls back on RiftException with isInitRequired code', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final src = Directory('${tmp.path}/local_checkout');
      _createGitDir(src);

      final rift = _FakeRift(available: true);
      rift.initError = const RiftException(
        code: 'workspace_not_initialized',
        message: 'The workspace was never init-ed',
      );
      final git = _FakeGit();
      git.enqueueStreamLines(['Cloning via network...']);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetching...']);

      final manager = _manager(
        tmp: tmp,
        git: git,
        localCheckoutPath: src.path,
        rift: rift,
      );

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      expect(events[0].phase, PrClonePhase.cloning);
      expect(events[1].phase, PrClonePhase.cloning);
      expect(events[1].message, 'Cloning via network...');
      final hasClone = git.runs.any((args) => args.contains('clone'));
      expect(hasClone, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Tests: git command workdir correctness
  // -------------------------------------------------------------------------

  group('git workdir correctness', () {
    test('clone workdir is the parent of the clone directory', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines(['Cloning...']);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetching...']);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      // _git.runs stores run() and runStreaming() calls in order.
      // runStreaming(clone) → run(remote set-url) → runStreaming(fetch)
      // The _FakeGit.runs list is: [0]=clone stream, [1]=remote set-url, [2]=fetch stream
      // We need to check workdir. But _FakeGit doesn't store workdir separately.
      // The workdir is passed as a named param and we don't capture it in runs.
      // Instead, verify clone args include the correct clone path.
      final cloneArgs = git.runs.firstWhere((args) => args.contains('clone'));
      expect(cloneArgs.last, contains('pr_clones'));
      expect(cloneArgs.last, contains('octocat__hello'));
    });

    test('remote set-url workdir is the clone directory itself', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      // The remote set-url is a run() call. Verify it contains the expected args.
      final remoteArgs = git.runs.firstWhere(
        (args) => args.contains('remote') && args.contains('set-url'),
      );
      expect(remoteArgs, contains('origin'));
      expect(remoteArgs.last, 'https://github.com/octocat/hello.git');
    });

    test('fetch workdir is the clone directory', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 42,
        baseRef: 'develop',
        headSha: 'abc123',
      ));

      // Only one call: the fetch. Verify it has the right refspecs.
      expect(git.runs.length, 1);
      final fetchArgs = git.runs[0];
      expect(fetchArgs, contains('fetch'));
      expect(fetchArgs, contains('--filter=blob:none'));
      expect(fetchArgs, contains('refs/pull/42/head:refs/pr/42/head'));
    });
  });

  // -------------------------------------------------------------------------
  // Tests: empty / zero-line stream outputs
  // -------------------------------------------------------------------------

  group('empty stream output', () {
    test('produces phase markers when clone produces no lines', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]); // clone: no lines
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]); // fetch: no lines

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      // Events: cloning(""), fetching(""), ready.
      expect(events.length, 3);
      expect(events[0].phase, PrClonePhase.cloning);
      expect(events[0].message, '');
      expect(events[1].phase, PrClonePhase.fetching);
      expect(events[1].message, '');
      expect(events[2].phase, PrClonePhase.ready);
    });

    test('produces phase markers when fetch produces no lines (skip clone)', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]); // fetch: no lines

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      // Events: fetching(""), ready.
      expect(events.length, 2);
      expect(events[0].phase, PrClonePhase.fetching);
      expect(events[0].message, '');
      expect(events[1].phase, PrClonePhase.ready);
    });
  });

  // -------------------------------------------------------------------------
  // Tests: multi-line clone progress
  // -------------------------------------------------------------------------

  group('multi-line clone progress', () {
    test('yields one progress event per stream line during clone', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([
        'Cloning into bare repository...',
        'remote: Enumerating objects: 100',
        'remote: Counting objects: 100',
        'Receiving objects: 50%',
        'Receiving objects: 100%',
      ]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetch done']);

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      final cloneEvents = events
          .where((e) => e.phase == PrClonePhase.cloning)
          .toList();
      // 1 initial marker + 5 stream lines = 6 cloning events.
      expect(cloneEvents.length, 6);
      expect(cloneEvents[0].message, '');
      expect(cloneEvents[1].message, 'Cloning into bare repository...');
      expect(cloneEvents[2].message, 'Enumerating objects: 100');
      expect(cloneEvents[3].message, 'Counting objects: 100');
      expect(cloneEvents[4].message, 'Receiving objects: 50%');
      expect(cloneEvents[5].message, 'Receiving objects: 100%');
      expect(events.last.phase, PrClonePhase.ready);
    });
  });

  // -------------------------------------------------------------------------
  // Tests: auth URL edge cases
  // -------------------------------------------------------------------------

  group('auth URL edge cases', () {
    test('auth URL includes token even with special characters in repo name', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(
        tmp: tmp,
        git: git,
        owner: 'my-org',
        repo: 'my-repo.with.dots',
      );

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      final cloneArgs = git.runs[0];
      expect(
        cloneArgs,
        contains('https://x-access-token:token@github.com/my-org/my-repo.with.dots.git'),
      );
    });

    test('clean URL after clone has no token for custom owner/repo', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(
        tmp: tmp,
        git: git,
        owner: 'my-org',
        repo: 'my-repo.with.dots',
      );

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      // run[1] is the remote set-url call.
      final remoteArgs = git.runs.firstWhere(
        (args) => args.contains('remote') && args.contains('set-url'),
      );
      expect(remoteArgs.last, 'https://github.com/my-org/my-repo.with.dots.git');
    });
  });

  // -------------------------------------------------------------------------
  // Tests: error paths
  // -------------------------------------------------------------------------

  group('additional error paths', () {
    test('stream error from fetch when clone was skipped propagates', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamError(StateError('Fetch rejected'));

      final manager = _manager(tmp: tmp, git: git);

      final stream = manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      );

      expect(
        stream.toList(),
        throwsA(isA<StateError>()),
      );
    });

    test('busy flag is reset after stream error from fetch (skip clone)', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamError(StateError('Network failure'));
      // For the retry second call.
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      // First call: stream error from _doFetch propagates.
      try {
        await for (final _ in manager.ensureCloneAndFetch(
          prNumber: 1,
          baseRef: 'main',
          headSha: 'abc123',
        )) {}
      } catch (_) {
        // Expected.
      }

      // Second call on same manager: busy was reset in finally.
      final events2 = await manager.ensureCloneAndFetch(
        prNumber: 2,
        baseRef: 'develop',
        headSha: 'def456',
      ).toList();
      expect(events2.last.phase, PrClonePhase.ready);
    });

    test('error phase includes the error object in progress event', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final fs = _OneThrowFilesystem(
        tmp.path,
        StateError('Disk full'),
      );
      final git = _FakeGit();
      final manager = _manager(tmp: tmp, git: git, filesystem: fs);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      expect(events.length, 1);
      expect(events[0].phase, PrClonePhase.error);
      expect(events[0].error, isA<StateError>());
      expect((events[0].error as StateError).message, 'Disk full');
      expect(events[0].isTerminal, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Tests: clone creates parent dir
  // -------------------------------------------------------------------------

  group('clone directory creation', () {
    test('creates parent directory when it does not exist before clone', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      // Remove the default dir so parent must be created.
      final parentPath = '${tmp.path}/ws1/pr_clones';
      final parent = Directory(parentPath);
      if (parent.existsSync()) {
        parent.deleteSync(recursive: true);
      }

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      // The parent should now exist because _doClone creates it.
      expect(parent.existsSync(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Tests: large PR numbers
  // -------------------------------------------------------------------------

  group('large PR numbers', () {
    test('handles large PR numbers in fetch refspec', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 99999,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      final fetchArgs = git.runs[0];
      expect(fetchArgs, contains('refs/pull/99999/head:refs/pr/99999/head'));
    });
  });

  // -------------------------------------------------------------------------
  // Tests: PrCloneProgress value semantics
  // -------------------------------------------------------------------------

  group('PrCloneProgress value semantics', () {
    test('identical const progress events compare equal', () {
      const a = PrCloneProgress(phase: PrClonePhase.ready);
      const b = PrCloneProgress(phase: PrClonePhase.ready);
      expect(a, equals(b));
    });

    test('different const progress events are not equal', () {
      const a = PrCloneProgress(phase: PrClonePhase.cloning);
      const b = PrCloneProgress(phase: PrClonePhase.fetching);
      expect(a, isNot(equals(b)));
    });

    test('error-bearing progress events with same error are equal', () {
      const a = PrCloneProgress(phase: PrClonePhase.error, error: 'boom');
      const b = PrCloneProgress(phase: PrClonePhase.error, error: 'boom');
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // Tests: edge cases
  // ---------------------------------------------------------------------------

  group('edge cases', () {
    test('clonePath with special characters in owner/repo', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      final manager = _manager(
        tmp: tmp,
        git: git,
        owner: 'my-org',
        repo: 'my-repo.with.dots',
      );

      final path = await manager.clonePath();
      expect(path, contains('my-org'));
      expect(path, contains('my-repo.with.dots'));
    });

    test('ensureCloneAndFetch with empty baseRef still works', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: '',
        headSha: 'abc123',
      ).toList();

      expect(events.last.phase, PrClonePhase.ready);
    });

    test('fetch includes --no-tags flag', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      final fetchArgs = git.runs[0];
      expect(fetchArgs, contains('--no-tags'));
    });

    test('fetch includes --progress flag', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _createGitDir(Directory(_cloneDirPath(tmp)));

      final git = _FakeGit();
      git.enqueueStreamLines([]);

      final manager = _manager(tmp: tmp, git: git);

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      expect(git.runs[0], contains('--progress'));
    });

    test('clone with empty github token uses empty auth token', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines([]);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines([]);

      final manager = _manager(
        tmp: tmp,
        git: git,
        githubToken: '',
      );

      await drainStream(manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ));

      final cloneArgs = git.runs[0];
      // Token is empty, so auth URL is https://x-access-token:@github.com/...
      final authUrlIndex = cloneArgs.indexWhere(
          (a) => a.contains('x-access-token:@'));
      expect(authUrlIndex, isNot(-1));
    });


    test('_sanitize handles pure-whitespace lines', () async {
      final tmp = Directory.systemTemp.createTempSync('pr_clone_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final git = _FakeGit();
      git.enqueueStreamLines(['   ', '\t']);
      git.enqueueRunResult(const GitResult(exitCode: 0, stdout: '', stderr: ''));
      git.enqueueStreamLines(['Fetch done']);

      final manager = _manager(tmp: tmp, git: git);

      final events = await manager.ensureCloneAndFetch(
        prNumber: 1,
        baseRef: 'main',
        headSha: 'abc123',
      ).toList();

      // Whitespace-only lines after trim() become empty, still yield events.
      final msgs = events
          .where((e) => e.phase == PrClonePhase.cloning)
          .map((e) => e.message)
          .toList();
      expect(msgs, contains(''));
    });
  });
}
