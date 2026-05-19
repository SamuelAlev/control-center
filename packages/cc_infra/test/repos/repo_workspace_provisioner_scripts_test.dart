import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/ports/repo_script_port.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart'
    show RepoScriptKind;
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/repos/repo_workspace_provisioner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The repo lifecycle script hooks: setup runs once, right after a worktree is
/// materialized and registered (a failure tears the unit back down so the
/// space's verification reports `failed`), and archive runs just before a
/// registered worktree is destroyed (best-effort, never blocking the GC).
void main() {
  late Directory root;
  late _LiveRegistry registry;
  late _RecordingIsolation isolation;
  late _FakeScriptPort scripts;

  RepoWorkspaceProvisioner buildProvisioner() => RepoWorkspaceProvisioner(
    filesystem: _FakeFilesystem(root.path),
    isolation: isolation,
    registry: registry,
    workspaces: _FakeWorkspaces([
      Repo(
        id: 'repo-1',
        name: 'web-app',
        path: '/src/web-app',
        remoteOwner: 'acme',
        remoteName: 'web-app',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]),
    githubToken: () async => null,
    branchTemplate: (_) async => '{type}/{key}',
    scripts: scripts,
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_provisioner_scripts');
    registry = _LiveRegistry();
    isolation = _RecordingIsolation();
    scripts = _FakeScriptPort();
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

  test('setup runs against the freshly registered worktree', () async {
    scripts.hasSetup = true;
    final provisioner = buildProvisioner();
    await provision(provisioner);

    expect(scripts.setupCalls, hasLength(1));
    final ctx = scripts.setupCalls.single;
    expect(ctx.repoId, 'repo-1');
    expect(
      ctx.worktreePath,
      p.join(root.path, 'spaces', 'sp-1', 'repos', 'web-app'),
    );
    expect(ctx.sourcePath, '/src/web-app');
  });

  test('a reused worktree never re-runs setup', () async {
    scripts.hasSetup = true;
    final provisioner = buildProvisioner();
    await provision(provisioner);
    await provision(provisioner);

    expect(
      scripts.setupCalls,
      hasLength(1),
      reason:
          'The reuse path must not re-pay an install on every dispatch into a '
          'warm space.',
    );
  });

  test(
    'no configured setup script means no run and no progress callback',
    () async {
      scripts.hasSetup = false;
      var stepFired = false;
      final provisioner = buildProvisioner();
      await provisioner.ensureSpaceWorkspace(
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        agentSlug: 'alice',
        fallbackDir: '',
        repoAllowlist: const {'repo-1'},
        onRepoSetupScript: (_) => stepFired = true,
      );

      expect(scripts.setupCalls, isEmpty);
      expect(stepFired, isFalse, reason: 'the step would flash a wrong label');
    },
  );

  test(
    'the setup progress callback fires only when a script will run',
    () async {
      scripts.hasSetup = true;
      final subjects = <String>[];
      final provisioner = buildProvisioner();
      await provisioner.ensureSpaceWorkspace(
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        agentSlug: 'alice',
        fallbackDir: '',
        repoAllowlist: const {'repo-1'},
        onRepoSetupScript: subjects.add,
      );

      expect(subjects, ['web-app']);
    },
  );

  test('a failed setup script tears the unit down and propagates', () async {
    scripts
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

  test('archive runs before destroy and a failure never blocks it', () async {
    scripts
      ..hasArchive = true
      ..failArchiveWith = StateError('docker: no such network');
    final provisioner = buildProvisioner();
    await provision(provisioner);
    expect(registry.rows, hasLength(1));

    await provisioner.releaseSpace(workspaceId: 'ws-1', spaceId: 'sp-1');

    expect(scripts.archiveCalls, hasLength(1));
    expect(scripts.archiveCalls.single.worktreePath, registry.rowsOld.single);
    expect(
      isolation.destroyed,
      hasLength(1),
      reason: 'a GC path must never be blocked by a script',
    );
    expect(registry.rows, isEmpty);
  });
}

class _FakeScriptPort implements RepoScriptPort {
  // The provisioning paths under test never start a test run; present to
  // satisfy the port.
  @override
  Future<String> runTest({
    required String workspaceId,
    required String repoId,
    required RepoScriptKind kind,
    required String body,
  }) => throw UnimplementedError();

  bool hasSetup = false;
  bool hasArchive = false;
  Object? failSetupWith;
  Object? failArchiveWith;

  final List<RepoScriptContext> setupCalls = [];
  final List<RepoScriptContext> archiveCalls = [];

  @override
  Future<bool> hasSetupScript(String workspaceId, String repoId) async =>
      hasSetup;

  @override
  Future<void> runSetup(RepoScriptContext context) async {
    setupCalls.add(context);
    final error = failSetupWith;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> runArchive(RepoScriptContext context) async {
    archiveCalls.add(context);
    final error = failArchiveWith;
    if (error != null) {
      throw error;
    }
  }
}

class _RecordingIsolation implements RepoIsolationPort {
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
  }) async {
    await Future<void>.delayed(Duration.zero);
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
