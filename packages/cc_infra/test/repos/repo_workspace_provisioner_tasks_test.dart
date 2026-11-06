import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/environments/domain/ports/worktree_task_port.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/repos/repo_workspace_provisioner.dart';
import 'package:cc_infra/src/repos/space_provisioning_log.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The worktree task hooks: provision runs once, right after a worktree is
/// materialized and registered (a failure tears the unit back down so the
/// space's verification reports `failed`), and archive runs just before a
/// registered worktree is destroyed (best-effort, never blocking the GC).
void main() {
  late Directory root;
  late _LiveRegistry registry;
  late _RecordingIsolation isolation;
  late _FakeTaskPort tasks;
  late InMemorySpaceProvisioningLog log;

  RepoWorkspaceProvisioner buildProvisioner() => RepoWorkspaceProvisioner(
    provisioningLog: log,
    filesystem: _FakeFilesystem(root.path),
    isolation: isolation,
    registry: registry,
    workspaces: _FakeWorkspaces([
      Repo(
        id: 'repo-1',
        name: 'shop-ui',
        path: '/src/shop-ui',
        remoteOwner: 'acme',
        remoteName: 'shop-ui',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]),
    githubToken: () async => null,
    branchTemplate: (_) async => '{type}/{key}',
    worktreeTasks: tasks,
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_provisioner_tasks');
    registry = _LiveRegistry();
    isolation = _RecordingIsolation();
    tasks = _FakeTaskPort();
    log = InMemorySpaceProvisioningLog();
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  Future<void> provision(RepoWorkspaceProvisioner provisioner) =>
      provisioner.ensureSpaceWorkspace(
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        agentSlug: 'alice',
        fallbackDir: '',
        repoAllowlist: const {'repo-1'},
      );

  Future<List<String>> logged() async {
    final lines = <String>[];
    final subscription = log
        .follow('ws-1', 'sp-1')
        .listen((line) => lines.add(line.text));
    await pumpEventQueue();
    await subscription.cancel();
    return lines;
  }

  test('the log tells the whole preparation, tasks included', () async {
    tasks
      ..hasSetup = true
      ..taskOutput = ['added 1200 packages'];
    isolation.output = ['Fetching main'];

    await provision(buildProvisioner());

    expect(await logged(), [
      'Preparing shop-ui on space/sp-1',
      'Fetching main',
      startsWith('shop-ui checked out in '),
      'Running provision tasks for shop-ui',
      'added 1200 packages',
      startsWith('Provision tasks for shop-ui finished in '),
    ]);
  });

  test('a reused worktree adds nothing to the log', () async {
    final provisioner = buildProvisioner();
    await provision(provisioner);
    final first = await logged();

    await provision(provisioner);

    expect(await logged(), first);
  });

  test('the log says why a repo could not be prepared', () async {
    tasks
      ..hasSetup = true
      ..failSetupWith = StateError('install failed\nthe whole npm output');

    await provision(buildProvisioner());

    final lines = await logged();
    expect(
      lines.last,
      'Could not prepare shop-ui: Bad state: install failed',
      reason: 'the output is in the log already; the reason should not be '
          'followed by a second copy of it',
    );
  });

  test('setup runs against the freshly registered worktree', () async {
    tasks.hasSetup = true;
    final provisioner = buildProvisioner();
    await provision(provisioner);

    expect(tasks.setupCalls, hasLength(1));
    final ctx = tasks.setupCalls.single;
    expect(ctx.repoId, 'repo-1');
    expect(
      ctx.worktreePath,
      p.join(root.path, 'spaces', 'sp-1', 'repos', 'shop-ui'),
    );
    expect(ctx.sourcePath, '/src/shop-ui');
  });

  test('a reused worktree never re-runs setup', () async {
    tasks.hasSetup = true;
    final provisioner = buildProvisioner();
    await provision(provisioner);
    await provision(provisioner);

    expect(
      tasks.setupCalls,
      hasLength(1),
      reason:
          'The reuse path must not re-pay an install on every dispatch into a '
          'warm space.',
    );
  });

  test(
    'no provision task means no run and no progress callback',
    () async {
      tasks.hasSetup = false;
      var stepFired = false;
      final provisioner = buildProvisioner();
      await provisioner.ensureSpaceWorkspace(
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        agentSlug: 'alice',
        fallbackDir: '',
        repoAllowlist: const {'repo-1'},
        onRepoProvisionTasks: (_) => stepFired = true,
      );

      expect(tasks.setupCalls, isEmpty);
      expect(stepFired, isFalse, reason: 'the step would flash a wrong label');
    },
  );

  test(
    'the setup progress callback fires only when a task will run',
    () async {
      tasks.hasSetup = true;
      final subjects = <String>[];
      final provisioner = buildProvisioner();
      await provisioner.ensureSpaceWorkspace(
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        agentSlug: 'alice',
        fallbackDir: '',
        repoAllowlist: const {'repo-1'},
        onRepoProvisionTasks: subjects.add,
      );

      expect(subjects, ['shop-ui']);
    },
  );

  test('a failed provision task tears the unit down and propagates', () async {
    tasks
      ..hasSetup = true
      ..failSetupWith = StateError('pnpm install exited 1');
    final provisioner = buildProvisioner();

    // `ensureSpaceWorkspace` never throws (the port contract: best-effort,
    // degrade to the fallback dir) — the failure surfaces downstream through
    // VERIFICATION, because the row is gone. What must hold here is the
    // teardown itself.
    await provision(provisioner);

    // The registry row and the worktree must both be gone, so the space's
    // post-hoc verification reads this exactly like a failed clone: `failed`,
    // with a retry that starts clean.
    expect(registry.rows, isEmpty);
    expect(isolation.destroyed, hasLength(1));
  });

  test('the environment goes first, and its failure never blocks', () async {
    tasks.failReleaseWith = StateError('docker: daemon gone');
    final provisioner = buildProvisioner();
    await provision(provisioner);

    await provisioner.releaseSpace(workspaceId: 'ws-1', spaceId: 'sp-1');

    expect(tasks.released, ['sp-1']);
    expect(isolation.destroyed, hasLength(1));
    expect(registry.rows, isEmpty);
  });

  test('archive runs before destroy and a failure never blocks it', () async {
    tasks
      ..hasArchive = true
      ..failArchiveWith = StateError('docker: no such network');
    final provisioner = buildProvisioner();
    await provision(provisioner);
    expect(registry.rows, hasLength(1));

    await provisioner.releaseSpace(workspaceId: 'ws-1', spaceId: 'sp-1');

    expect(tasks.archiveCalls, hasLength(1));
    expect(tasks.archiveCalls.single.worktreePath, registry.rowsOld.single);
    expect(
      isolation.destroyed,
      hasLength(1),
      reason: 'a GC path must never be blocked by a script',
    );
    expect(registry.rows, isEmpty);
  });
}

class _FakeTaskPort implements WorktreeTaskPort {
  bool hasSetup = false;
  bool hasArchive = false;
  Object? failSetupWith;
  Object? failArchiveWith;
  Object? failReleaseWith;
  final List<String> released = [];

  /// Printed by every `provision` run.
  List<String> taskOutput = const [];

  final List<WorktreeTaskContext> setupCalls = [];
  final List<WorktreeTaskContext> archiveCalls = [];

  @override
  Future<bool> hasProvisionTasks(String workspaceId, String repoId) async =>
      hasSetup;

  @override
  Future<Set<String>> reposWithEnvironments(String workspaceId) async => const {};

  @override
  Future<void> runProvision(
    WorktreeTaskContext context, {
    void Function(String line)? onOutput,
  }) async {
    setupCalls.add(context);
    taskOutput.forEach(onOutput ?? (_) {});
    final error = failSetupWith;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> beforeRelease(String workspaceId, String spaceId) async {
    released.add(spaceId);
    final error = failReleaseWith;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> runArchive(WorktreeTaskContext context) async {
    archiveCalls.add(context);
    final error = failArchiveWith;
    if (error != null) {
      throw error;
    }
  }
}

class _RecordingIsolation implements RepoIsolationPort {
  /// Printed by every provision.
  List<String> output = const [];

  final List<String> provisioned = [];
  final List<String> destroyed = [];

  @override
  bool get isCowAvailable => true;

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
    void Function(String line)? onOutput,
  }) async {
    await Future<void>.delayed(Duration.zero);
    output.forEach(onOutput ?? (_) {});
    final path = p.join(destParentDir, name);
    Directory(path).createSync(recursive: true);
    provisioned.add(path);
    return RepoIsolationResult(path: path, backend: RepoIsolationBackend.rift);
  }

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
    List<String> branches = const [],
  }) async {
    destroyed.add(path);
    final dir = Directory(path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LiveRegistry implements IsolatedRepoRepository {
  final List<IsolatedRepo> rows = [];
  final List<String> rowsOld = [];

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    await Future<void>.delayed(Duration.zero);
    for (final row in rows) {
      if (row.workspaceId == workspaceId &&
          row.spaceId == spaceId &&
          row.repoId == repoId) {
        return row;
      }
    }
    return null;
  }

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => [
    for (final row in rows)
      if (row.spaceId == spaceId) row,
  ];

  @override
  Future<void> upsert(IsolatedRepo repo) async {
    rows
      ..removeWhere(
        (r) =>
            r.workspaceId == repo.workspaceId &&
            r.spaceId == repo.spaceId &&
            r.repoId == repo.repoId,
      )
      ..add(repo);
  }

  @override
  Future<void> deleteById(String workspaceId, String id) async {
    for (final row in rows) {
      if (row.id == id) {
        rowsOld.add(row.path);
      }
    }
    rows.removeWhere((r) => r.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFilesystem implements WorkspaceFilesystemPort {
  _FakeFilesystem(this.root);

  final String root;

  @override
  Future<String> ensureSpaceDir(String workspaceId, String spaceId) async {
    final dir = Directory(p.join(root, 'spaces', spaceId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkspaces implements WorkspaceRepository {
  _FakeWorkspaces(this.repos);

  final List<Repo> repos;

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(repos);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
