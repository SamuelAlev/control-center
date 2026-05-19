import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_infra/src/repos/repo_workspace_provisioner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_filesystem_port.dart';

class _FakeIsolation implements RepoIsolationPort {
  final List<String> destroyed = [];
  final List<_ProvisionCall> provisions = [];

  @override
  bool get isCowAvailable => false;

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
    provisions.add(_ProvisionCall(
      sourcePath: sourcePath,
      destParentDir: destParentDir,
      name: name,
      branch: branch,
      authUrl: authUrl,
    ));
    return RepoIsolationResult(
      path: '$destParentDir/$name',
      backend: RepoIsolationBackend.rift,
    );
  }

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async =>
      destroyed.add(path);
}

class _ProvisionCall {
  const _ProvisionCall({
    required this.sourcePath,
    required this.destParentDir,
    required this.name,
    required this.branch,
    this.authUrl,
  });
  final String sourcePath;
  final String destParentDir;
  final String name;
  final String branch;
  final String? authUrl;
}

class _FakeRegistry implements IsolatedRepoRepository {
  final List<IsolatedRepo> rows = [];

  @override
  Future<List<IsolatedRepo>> forChannel(String workspaceId, String channelId) async =>
      rows
          .where((r) => r.workspaceId == workspaceId && r.channelId == channelId)
          .toList();

  @override
  Future<List<IsolatedRepo>> forChannelAcrossWorkspaces(String channelId) async =>
      rows.where((r) => r.channelId == channelId).toList();

  @override
  Future<List<IsolatedRepo>> forTicket(String workspaceId, String ticketId) async =>
      rows
          .where((r) => r.workspaceId == workspaceId && r.ticketId == ticketId)
          .toList();

  @override
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(String ticketId) async =>
      rows.where((r) => r.ticketId == ticketId).toList();

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String channelId,
    String repoId,
  ) async =>
      rows
          .where((r) =>
              r.workspaceId == workspaceId &&
              r.channelId == channelId &&
              r.repoId == repoId)
          .firstOrNull;

  @override
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId) =>
      Stream.value(rows.where((r) => r.workspaceId == workspaceId).toList());

  @override
  Future<void> upsert(IsolatedRepo repo) async {
    rows.removeWhere((r) => r.id == repo.id);
    rows.add(repo);
  }

  @override
  Future<void> deleteById(String id) async => rows.removeWhere((r) => r.id == id);
}

class _FakeWorkspaces implements WorkspaceRepository {
  _FakeWorkspaces(this._repos);
  final List<Repo> _repos;

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(_repos);

  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) async =>
      _repos.any((r) => r.id == repoId);

  @override
  Stream<List<Workspace>> watchAll() => const Stream.empty();
  @override
  Future<String> upsert(Workspace workspace) async => workspace.id;
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds) async {}
  @override
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) async {}
  @override
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) async {}
}

IsolatedRepo _row(String id, String ws, String ch, {String? ticketId}) =>
    IsolatedRepo(
      id: id,
      workspaceId: ws,
      channelId: ch,
      repoId: 'r-1',
      path: '/iso/$id',
      branch: 'feature/$id',
      backend: RepoIsolationBackend.rift,
      sourcePath: '/src',
      ticketId: ticketId,
      createdAt: DateTime(2026),
    );

Repo _makeRepo({
  String id = 'r-1',
  String name = 'owner/repo',
  String path = '/tmp/test-repo',
  String githubOwner = 'owner',
  String githubRepoName = 'repo',
}) =>
    Repo(
      id: id,
      name: name,
      path: path,
      githubOwner: githubOwner,
      githubRepoName: githubRepoName,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

/// Builds a provisioner with plain fakes (no real filesystem).
RepoWorkspaceProvisioner _build({
  required IsolatedRepoRepository registry,
  required RepoIsolationPort isolation,
  List<Repo> repos = const [],
  FakeFilesystemPort? filesystem,
  Future<String?> Function()? githubToken,
  String Function()? branchTemplate,
}) =>
    RepoWorkspaceProvisioner(
      filesystem: filesystem ?? FakeFilesystemPort(),
      isolation: isolation,
      registry: registry,
      workspaces: _FakeWorkspaces(repos),
      githubToken: githubToken ?? (() async => ''),
      branchTemplate: branchTemplate ?? (() => '{type}/{ticket-key}-{slug}'),
      mcpConfigPath: () async => '/nonexistent/.mcp.json',
    );

void main() {
  group('RepoWorkspaceProvisioner', () {
    // ── Guard paths ──────────────────────────────────────────────────────

    test('returns the fallback dir when the workspace has no linked repos',
        () async {
      final p = _build(registry: _FakeRegistry(), isolation: _FakeIsolation());
      final dir = await p.ensureConversationWorkspace(
        workspaceId: 'w-1',
        channelId: 'ch',
        fallbackDir: '/agent/dir',
      );
      expect(dir, '/agent/dir');
    });

    test('returns the fallback dir when workspaceId is empty', () async {
      final p = _build(registry: _FakeRegistry(), isolation: _FakeIsolation());
      expect(
        await p.ensureConversationWorkspace(
          workspaceId: '',
          channelId: 'ch',
          fallbackDir: '/fallback',
        ),
        '/fallback',
      );
    });

    test('returns the fallback dir when channelId is empty', () async {
      final p = _build(registry: _FakeRegistry(), isolation: _FakeIsolation());
      expect(
        await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: '',
          fallbackDir: '/fallback',
        ),
        '/fallback',
      );
    });

    // ── Provisioning flow (filesystem-backed) ────────────────────────────

    test('provisions repos into conversation dir and returns its path',
        () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_provision_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        final dir = await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch-12345678',
          fallbackDir: '/fallback',
        );

        expect(dir, '${tempDir.path}/w-1/conversations/ch-12345678');
        expect(isolation.provisions, hasLength(1));
        expect(
          isolation.provisions.first.sourcePath,
          repo.path,
        );
        expect(
          isolation.provisions.first.destParentDir,
          '${tempDir.path}/w-1/conversations/ch-12345678/repos',
        );
        expect(isolation.provisions.first.name, 'repo');
        // Without ticket key/title, branch defaults to conv/<short-channel>
        expect(isolation.provisions.first.branch, 'conv/ch-12345');
        expect(registry.rows, hasLength(1));
        expect(registry.rows.first.workspaceId, 'w-1');
        expect(registry.rows.first.channelId, 'ch-12345678');
        expect(registry.rows.first.repoId, 'r-1');
        expect(registry.rows.first.branch, 'conv/ch-12345');
        expect(registry.rows.first.backend, RepoIsolationBackend.rift);
        expect(registry.rows.first.sourcePath, repo.path);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('branch naming uses ticket key/title when provided', () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_branch_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch-12345678',
          fallbackDir: '/fallback',
          ticketKey: 'OMP-42',
          ticketTitle: 'Fix the thing',
          branchType: 'bugfix',
        );

        // BranchTemplateResolver renders {type}/{ticket-key}-{slug}
        // → bugfix/OMP-42-fix-the-thing
        expect(isolation.provisions.first.branch, 'bugfix/OMP-42-fix-the-thing');
        expect(registry.rows.first.ticketId, null); // ticketId not passed
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('branch naming uses ticketId when passed', () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_ticket_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch-12345678',
          fallbackDir: '/fallback',
          ticketId: 't-42',
          ticketKey: 'OMP-42',
          ticketTitle: 'Fix the thing',
        );

        expect(registry.rows.first.ticketId, 't-42');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('slugifies repo name for worktree directory', () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_slugify_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo(
          name: 'My Awesome Repo!!',
          githubRepoName: 'my-awesome-repo!!',
        );

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch',
          fallbackDir: '/fallback',
        );

        // slugify('my-awesome-repo!!') → 'my-awesome-repo'
        expect(isolation.provisions.first.name, 'my-awesome-repo');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('fallback repo name to id when slug is empty', () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_empty_slug_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo(
          name: '!!!',
          githubRepoName: '',
          id: 'my-repo-id',
        );

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch',
          fallbackDir: '/fallback',
        );

        expect(isolation.provisions.first.name, 'my-repo-id');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('passes authUrl when repo has GitHub remote and token is available',
        () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_auth_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo(
          githubOwner: 'alice',
          githubRepoName: 'widgets',
        );

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
          githubToken: () async => 'ghp_token',
        );

        await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch',
          fallbackDir: '/fallback',
        );

        expect(
          isolation.provisions.first.authUrl,
          'https://x-access-token:ghp_token@github.com/alice/widgets.git',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('does not pass authUrl when token is empty', () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_no_auth_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
          githubToken: () async => '',
        );

        await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch',
          fallbackDir: '/fallback',
        );

        expect(isolation.provisions.first.authUrl, isNull);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('safeToken catches exceptions from token provider', () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_token_err_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
          githubToken: () async => throw Exception('auth failed'),
        );

        final dir = await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch',
          fallbackDir: '/fallback',
        );

        // Should not crash; authUrl will be null since token is null
        expect(dir, isNot('/fallback'));
        expect(isolation.provisions.first.authUrl, isNull);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    // ── Worktree reuse ───────────────────────────────────────────────────

    test('reuses existing worktree when registry entry and directory exist',
        () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_reuse_');
      try {
        // Create the "existing" worktree directory on disk
        final worktreePath = '${tempDir.path}/w-1/conversations/ch/repos/owner-repo';
        await Directory(worktreePath).create(recursive: true);

        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry()
          ..rows.add(IsolatedRepo(
            id: 'existing-id',
            workspaceId: 'w-1',
            channelId: 'ch',
            repoId: 'r-1',
            path: worktreePath,
            branch: 'conv/ch',
            backend: RepoIsolationBackend.rift,
            sourcePath: '/tmp/test-repo',
            createdAt: DateTime(2026),
          ));
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        final dir = await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch',
          fallbackDir: '/fallback',
        );

        expect(dir, '${tempDir.path}/w-1/conversations/ch');
        // Should NOT have provisioned — reuse
        expect(isolation.provisions, isEmpty);
        // Registry should still have just the original entry
        expect(registry.rows, hasLength(1));
        expect(registry.rows.first.id, 'existing-id');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('destroys stale entry and reprovisions when worktree directory gone',
        () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_stale_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        // Path points to nonexistent dir — stale
        final stalePath = '${tempDir.path}/w-1/conversations/ch/repos/owner-repo';
        final registry = _FakeRegistry()
          ..rows.add(IsolatedRepo(
            id: 'stale-id',
            workspaceId: 'w-1',
            channelId: 'ch',
            repoId: 'r-1',
            path: stalePath,
            branch: 'old-branch',
            backend: RepoIsolationBackend.gitWorktree,
            sourcePath: '/tmp/test-repo',
            createdAt: DateTime(2026),
          ));
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        final dir = await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch',
          fallbackDir: '/fallback',
        );

        expect(dir, '${tempDir.path}/w-1/conversations/ch');

        // Stale entry destroyed
        expect(isolation.destroyed, contains(stalePath));

        // Reprovisioned
        expect(isolation.provisions, hasLength(1));
        expect(isolation.provisions.first.name, 'repo');

        // Old row deleted, new one upserted
        expect(
          registry.rows.where((r) => r.id == 'stale-id'),
          isEmpty,
        );
        expect(registry.rows, hasLength(1));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    // ── Per-repo failure isolation ───────────────────────────────────────

    test('one repo failing to provision does not block others', () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_partial_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final r1Path = '${tempDir.path}/w-1/conversations/ch-12/repos/repo';
        // ThrowingIsolation throws on destroy for r1's stale path, simulating
        // a failed _ensureRepo for r-1. r-2 should still provision fine.
        final isolation = _ThrowingIsolation(failOnPath: r1Path);
        final registry = _FakeRegistry();
        final repo1 = _makeRepo(id: 'r-1');
        final repo2 = _makeRepo(id: 'r-2', githubRepoName: 'other-repo');

        // Pre-populate a stale row for r-1 so destroy is called and throws
        registry.rows.add(IsolatedRepo(
          id: 'stale',
          workspaceId: 'w-1',
          channelId: 'ch-12',
          repoId: 'r-1',
          path: r1Path,
          branch: 'old',
          backend: RepoIsolationBackend.rift,
          sourcePath: '/tmp/test-repo',
          createdAt: DateTime(2026),
        ));

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo1, repo2],
          filesystem: fs,
        );

        final dir = await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: 'ch-12',
          fallbackDir: '/fallback',
        );

        // Should still return the conv dir (not fallback)
        expect(dir, '${tempDir.path}/w-1/conversations/ch-12');

        // Provision should have happened only for the second repo
        expect(isolation.provisions, hasLength(1));
        expect(isolation.provisions.first.name, 'other-repo');

        // Registry should have only repo2's entry (stale was deleted, r-1 failed)
        expect(
          registry.rows.where((r) => r.repoId == 'r-2'),
          hasLength(1),
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    // ── Top-level exception resilience ───────────────────────────────────

    test('ensureConversationWorkspace returns fallbackDir on top-level error',
        () async {
      // WorkspaceRepository that throws on watchReposForWorkspace
      final thrower = _ThrowingWorkspaces();
      final p = RepoWorkspaceProvisioner(
        filesystem: FakeFilesystemPort(),
        isolation: _FakeIsolation(),
        registry: _FakeRegistry(),
        workspaces: thrower,
        githubToken: () async => '',
        branchTemplate: () => '{type}/{ticket-key}-{slug}',
        mcpConfigPath: () async => '/nonexistent/.mcp.json',
      );

      final dir = await p.ensureConversationWorkspace(
        workspaceId: 'w-1',
        channelId: 'ch',
        fallbackDir: '/safe-fallback',
      );

      expect(dir, '/safe-fallback');
    });

    // ── Release paths ────────────────────────────────────────────────────

    test('releaseConversation destroys + deletes every worktree for the channel',
        () async {
      final registry = _FakeRegistry()
        ..rows.addAll([
          _row('a', 'w-1', 'ch'),
          _row('b', 'w-1', 'ch'),
          _row('c', 'w-1', 'other'),
        ]);
      final isolation = _FakeIsolation();
      final p = _build(registry: registry, isolation: isolation);

      await p.releaseConversation(workspaceId: 'w-1', channelId: 'ch');

      expect(isolation.destroyed.toSet(), {'/iso/a', '/iso/b'});
      expect(registry.rows.map((r) => r.id), ['c']);
    });

    test('releaseConversationAnyWorkspace destroys across all workspaces',
        () async {
      final registry = _FakeRegistry()
        ..rows.addAll([
          _row('a', 'w-1', 'ch'),
          _row('b', 'w-2', 'ch'),
          _row('c', 'w-3', 'other'),
        ]);
      final isolation = _FakeIsolation();
      final p = _build(registry: registry, isolation: isolation);

      await p.releaseConversationAnyWorkspace(channelId: 'ch');

      expect(isolation.destroyed.toSet(), {'/iso/a', '/iso/b'});
      expect(registry.rows.map((r) => r.id), ['c']);
    });

    test('releaseTicket destroys worktrees across workspaces', () async {
      final registry = _FakeRegistry()
        ..rows.addAll([
          _row('a', 'w-1', 'ch', ticketId: 't-1'),
          _row('b', 'w-2', 'ch2', ticketId: 't-1'),
          _row('c', 'w-1', 'ch3', ticketId: 't-9'),
        ]);
      final isolation = _FakeIsolation();
      final p = _build(registry: registry, isolation: isolation);

      await p.releaseTicket(ticketId: 't-1');

      expect(isolation.destroyed.toSet(), {'/iso/a', '/iso/b'});
      expect(registry.rows.map((r) => r.id), ['c']);
    });

    test('destroyAll continues after per-row destruction failure', () async {
      final rows = [
        _row('a', 'w-1', 'ch'),
        _row('b', 'w-1', 'ch'),
        _row('c', 'w-1', 'ch'),
      ];
      final registry = _FakeRegistry()..rows.addAll(rows);

      // An isolation that throws on destroy for row 'b'
      final faultyIsolation = _ThrowingIsolation(failOnPath: '/iso/b');
      final p = _build(registry: registry, isolation: faultyIsolation);

      await p.releaseConversation(workspaceId: 'w-1', channelId: 'ch');

      // All rows should still be deleted from registry despite the throw
      expect(registry.rows, isEmpty);
      // Destroys that succeeded
      expect(faultyIsolation.destroyed, contains('/iso/a'));
      expect(faultyIsolation.destroyed, contains('/iso/c'));
    });

    // ── Short channel helper ─────────────────────────────────────────────

    test('short channel id truncates to first 8 chars', () async {
      final tempDir = Directory.systemTemp
          .createTempSync('provisioner_test_short_');
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        await p.ensureConversationWorkspace(
          workspaceId: 'w-1',
          channelId: '12345678901234',
          fallbackDir: '/fallback',
        );

        expect(isolation.provisions.first.branch, 'conv/12345678');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    // ── Workspace-scoped ticket release ──────────────────────────────────

    test('releaseTicketInWorkspace destroys only the matching workspace rows',
        () async {
      final registry = _FakeRegistry()
        ..rows.addAll([
          _row('a', 'w-1', 'ch', ticketId: 't-1'),
          _row('b', 'w-2', 'ch2', ticketId: 't-1'),
        ]);
      final isolation = _FakeIsolation();
      final p = _build(registry: registry, isolation: isolation);

      final n =
          await p.releaseTicketInWorkspace(workspaceId: 'w-1', ticketId: 't-1');

      expect(n, 1);
      expect(isolation.destroyed, ['/iso/a']);
      expect(registry.rows.map((r) => r.id), ['b']);
    });

    test('releaseTicketInWorkspace is a no-op for a foreign-workspace ticket',
        () async {
      final registry = _FakeRegistry()
        ..rows.add(_row('a', 'w-2', 'ch', ticketId: 't-1'));
      final isolation = _FakeIsolation();
      final p = _build(registry: registry, isolation: isolation);

      final n =
          await p.releaseTicketInWorkspace(workspaceId: 'w-1', ticketId: 't-1');

      expect(n, 0);
      expect(isolation.destroyed, isEmpty);
      expect(registry.rows.map((r) => r.id), ['a']);
    });

    test('releaseTicketInWorkspace returns 0 for empty args', () async {
      final p = _build(registry: _FakeRegistry(), isolation: _FakeIsolation());
      expect(
        await p.releaseTicketInWorkspace(workspaceId: '', ticketId: 't'),
        0,
      );
      expect(
        await p.releaseTicketInWorkspace(workspaceId: 'w', ticketId: ''),
        0,
      );
    });

    // ── Stale sweep ──────────────────────────────────────────────────────

    test('sweepStale reaps rows whose on-disk worktree has vanished', () async {
      final tempDir =
          Directory.systemTemp.createTempSync('provisioner_test_sweep_');
      try {
        final liveDir = Directory('${tempDir.path}/live')..createSync();
        final live = IsolatedRepo(
          id: 'live',
          workspaceId: 'w-1',
          channelId: 'ch-live',
          repoId: 'r-1',
          path: liveDir.path,
          branch: 'b',
          backend: RepoIsolationBackend.rift,
          sourcePath: '/src',
          createdAt: DateTime(2026),
        );
        final gone = IsolatedRepo(
          id: 'gone',
          workspaceId: 'w-1',
          channelId: 'ch-gone',
          repoId: 'r-1',
          path: '${tempDir.path}/vanished',
          branch: 'b',
          backend: RepoIsolationBackend.rift,
          sourcePath: '/src',
          createdAt: DateTime(2026),
        );
        final registry = _FakeRegistry()..rows.addAll([live, gone]);
        final isolation = _FakeIsolation();
        final p = _build(registry: registry, isolation: isolation);

        final reaped = await p.sweepStale(workspaceId: 'w-1');

        expect(reaped, 1);
        expect(isolation.destroyed, ['${tempDir.path}/vanished']);
        expect(registry.rows.map((r) => r.id), ['live']);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('sweepStale only touches the given workspace', () async {
      final registry = _FakeRegistry()
        ..rows.addAll([
          _row('a', 'w-1', 'ch'), // /iso/a — vanished
          _row('b', 'w-2', 'ch'), // other workspace — ignored
        ]);
      final isolation = _FakeIsolation();
      final p = _build(registry: registry, isolation: isolation);

      final reaped = await p.sweepStale(workspaceId: 'w-1');

      expect(reaped, 1);
      expect(isolation.destroyed, ['/iso/a']);
      expect(registry.rows.map((r) => r.id), ['b']);
    });

    test('sweepStale returns 0 for an empty workspaceId', () async {
      final p = _build(registry: _FakeRegistry(), isolation: _FakeIsolation());
      expect(await p.sweepStale(workspaceId: ''), 0);
    });
  });
}

// ── Throwing fakes for error-path tests ──────────────────────────────────

class _ThrowingWorkspaces implements WorkspaceRepository {
  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      throw Exception('BOOM');

  @override
  Stream<List<Workspace>> watchAll() => throw UnimplementedError();
  @override
  Future<String> upsert(Workspace workspace) => throw UnimplementedError();
  @override
  Future<void> delete(String id) => throw UnimplementedError();
  @override
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds) =>
      throw UnimplementedError();
  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      throw UnimplementedError();
  @override
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) =>
      throw UnimplementedError();
  @override
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) =>
      throw UnimplementedError();
}

class _ThrowingIsolation implements RepoIsolationPort {
  _ThrowingIsolation({required this.failOnPath});
  final String failOnPath;
  final List<String> destroyed = [];
  final List<_ProvisionCall> provisions = [];

  @override
  bool get isCowAvailable => false;

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
    provisions.add(_ProvisionCall(
      sourcePath: sourcePath,
      destParentDir: destParentDir,
      name: name,
      branch: branch,
      authUrl: authUrl,
    ));
    return RepoIsolationResult(
      path: '$destParentDir/$name',
      backend: RepoIsolationBackend.rift,
    );
  }

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async {
    if (path == failOnPath) {
      throw Exception('destroy failed');
    }
    destroyed.add(path);
  }
}
