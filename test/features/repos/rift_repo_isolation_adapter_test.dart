import 'dart:io';

import 'package:control_center/core/domain/ports/git_command_port.dart';
import 'package:control_center/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:control_center/core/infrastructure/rift/rift_client.dart';
import 'package:control_center/core/infrastructure/rift/rift_exception.dart';
import 'package:control_center/features/repos/data/adapters/rift_repo_isolation_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRift extends RiftClient {
  _FakeRift({this.available = true, this.createError})
      : super(dylibPaths: const [], databasePath: 'mem');

  final bool available;
  final RiftException? createError;
  final List<String> calls = [];

  @override
  bool get isAvailable => available;

  @override
  Future<void> init({required String at}) async => calls.add('init:$at');

  @override
  Future<String> create({
    required String from,
    required String into,
    String? name,
    bool copyAll = true,
    bool hooks = false,
  }) async {
    calls.add('create');
    final err = createError;
    if (err != null) throw err;
    return '$into/$name';
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
  final List<List<String>> runs = [];

  @override
  Future<GitResult> run(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
  }) async {
    runs.add(args);
    if (args.contains('symbolic-ref')) {
      return const GitResult(exitCode: 0, stdout: 'origin/main\n', stderr: '');
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
}

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

  test('falls back to git worktree when rift is unavailable', () async {
    final rift = _FakeRift(available: false);
    final git = _FakeGit();
    final adapter = RiftRepoIsolationAdapter(rift: rift, git: git);

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
  });

  test('uses rift when available and creates a branch (no worktree add)', () async {
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = RiftRepoIsolationAdapter(rift: rift, git: git);

    final result = await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'feature/x',
    );

    expect(result.backend, RepoIsolationBackend.rift);
    expect(rift.calls, contains('init:/src/repo'));
    expect(rift.calls, contains('create'));
    expect(git.ran((a) => a.contains('checkout') && a.contains('-b')), isTrue);
    expect(git.ran((a) => a.contains('worktree')), isFalse);
  });

  test('falls back to git worktree on cow_unavailable', () async {
    final rift = _FakeRift(
      createError: const RiftException(
        code: 'cow_unavailable',
        message: 'no CoW',
      ),
    );
    final git = _FakeGit();
    final adapter = RiftRepoIsolationAdapter(rift: rift, git: git);

    final result = await adapter.provision(
      sourcePath: '/src/repo',
      destParentDir: tmp.path,
      name: 'repo',
      branch: 'feature/x',
    );

    expect(result.backend, RepoIsolationBackend.gitWorktree);
    expect(
      git.ran((a) => a.length >= 2 && a[0] == 'worktree' && a[1] == 'add'),
      isTrue,
    );
  });

  test('rethrows on unsafe_git (no worktree fallback)', () async {
    final rift = _FakeRift(
      createError: const RiftException(
        code: 'unsafe_git',
        message: 'merge in progress',
      ),
    );
    final git = _FakeGit();
    final adapter = RiftRepoIsolationAdapter(rift: rift, git: git);

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

  test('destroy uses rift remove + gc for the rift backend', () async {
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = RiftRepoIsolationAdapter(rift: rift, git: git);

    await adapter.destroy(
      path: '/iso/repo',
      sourcePath: '/src/repo',
      backend: RepoIsolationBackend.rift,
      branch: 'feature/x',
    );

    expect(rift.calls, contains('remove:/iso/repo'));
    expect(rift.calls, contains('gc'));
  });

  test('destroy removes worktree + branch for the worktree backend', () async {
    final rift = _FakeRift();
    final git = _FakeGit();
    final adapter = RiftRepoIsolationAdapter(rift: rift, git: git);

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
}
