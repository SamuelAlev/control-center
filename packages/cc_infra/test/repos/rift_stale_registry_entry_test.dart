import 'dart:io';

import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/repos/rift_repo_isolation_adapter.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// rift's `path` column is UNIQUE, so `already_exists` is a REGISTRY verdict and
/// is returned just the same when the directory that entry described is gone —
/// which is what tearing a worktree down without pruning leaves behind. Nothing
/// expires such an entry, so without recovery every later create at that path is
/// refused and silently degrades to `git worktree` for good.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('cc_rift_stale'));
  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  RiftRepoIsolationAdapter adapterFor(_FakeRift rift) =>
      RiftRepoIsolationAdapter(
        rift: rift,
        git: _OkGit(),
        missingRiftIsExpected: false,
      );

  test('a registry entry whose directory is gone is pruned and the create '
      'retried on the CoW backend', () async {
    final rift = _FakeRift(failFirstCreateWith: 'already_exists');
    final result = await adapterFor(rift).provision(
      sourcePath: '/src/web-app',
      destParentDir: root.path,
      name: 'web-app',
      branch: 'pr/42',
      headRef: 'refs/pull/42/head',
      authUrl: 'https://github.com/acme/web-app.git',
    );

    expect(
      result.backend,
      RepoIsolationBackend.rift,
      reason: 'degrading here pins this path to git worktree for ever',
    );
    expect(rift.createCalls, 2, reason: 'the create must be retried once');
    expect(rift.removed, [p.join(root.path, 'web-app')]);
    expect(rift.gcCalls, greaterThanOrEqualTo(1));
  });

  test('a destination that really is on disk is left alone', () async {
    // A live managed copy is somebody's worktree; tearing it down from inside a
    // create is not this layer's call. With nowhere safe to degrade to — the
    // git-worktree backend writes into the user's checkout — the create's own
    // verdict is what the caller gets.
    Directory(p.join(root.path, 'web-app')).createSync(recursive: true);
    final rift = _FakeRift(failFirstCreateWith: 'already_exists');

    await expectLater(
      adapterFor(rift).provision(
        sourcePath: '/src/web-app',
        destParentDir: root.path,
        name: 'web-app',
        branch: 'pr/42',
        headRef: 'refs/pull/42/head',
        authUrl: 'https://github.com/acme/web-app.git',
      ),
      throwsA(
        isA<RiftException>().having((e) => e.code, 'code', 'already_exists'),
      ),
    );
    expect(rift.createCalls, 1);
    expect(rift.removed, isEmpty, reason: 'a live copy must not be removed');
  });

  test('destroy gc\'s again after deleting a directory rift left behind, so '
      'the entry cannot outlive it', () async {
    // The first gc runs while the directory is still there, so it cannot see
    // the entry as missing — which is exactly how the stale row above was
    // minted. Only a second pass, after the delete, can prune it.
    final dir = Directory(p.join(root.path, 'web-app'))
      ..createSync(recursive: true);
    final rift = _FakeRift(removeLeavesDirectory: true);

    await adapterFor(rift).destroy(
      path: dir.path,
      sourcePath: '/src/web-app',
      backend: RepoIsolationBackend.rift,
      branch: 'pr/42',
    );

    expect(dir.existsSync(), isFalse);
    expect(
      rift.gcCalls,
      2,
      reason: 'the pruning pass has to run after the directory is gone',
    );
  });
}

class _FakeRift implements RiftClient {
  _FakeRift({this.failFirstCreateWith, this.removeLeavesDirectory = false});

  /// Error code the FIRST create answers with, or null to always succeed.
  final String? failFirstCreateWith;

  /// Mimics rift leaving the directory behind on `remove` (what drives the
  /// adapter's belt-and-suspenders delete).
  final bool removeLeavesDirectory;

  int createCalls = 0;
  int gcCalls = 0;
  final List<String> removed = [];

  @override
  bool get isAvailable => true;

  @override
  Future<void> init({required String at}) async {}

  @override
  Future<String> create({
    required String from,
    required String into,
    String? name,
    bool copyAll = true,
    bool hooks = false,
  }) async {
    createCalls++;
    if (createCalls == 1 && failFirstCreateWith != null) {
      throw RiftException(
        code: failFirstCreateWith!,
        message: 'rift directory already exists',
        path: p.join(into, name ?? ''),
      );
    }
    final path = p.join(into, name ?? '');
    Directory(path).createSync(recursive: true);
    return path;
  }

  @override
  Future<void> remove({required String at}) async {
    removed.add(at);
    if (removeLeavesDirectory) {
      return;
    }
    final dir = Directory(at);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  @override
  Future<List<String>> gc() async {
    gcCalls++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Every git command succeeds with empty output — the fetch/branch/worktree
/// mechanics are not what these tests are about.
class _OkGit implements GitCommandPort {
  @override
  Future<GitResult> run(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
    CancellationToken? cancel,
  }) async {
    // `git worktree add` is the fallback backend's create — materialize the
    // directory so the result is indistinguishable from the real thing.
    if (args.contains('worktree') && args.contains('add')) {
      Directory(args.last).createSync(recursive: true);
    }
    // Repo discovery: a real checkout reports itself as its own toplevel. The
    // adapter refuses to mutate anything that reports a DIFFERENT root, which
    // is what keeps a stray directory from being treated as the repo above it.
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
  }) => const Stream.empty();
}
