import 'package:control_center/core/domain/entities/isolated_repo.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/ports/repo_isolation_port.dart';
import 'package:control_center/core/domain/repositories/isolated_repo_repository.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:control_center/features/repos/data/services/repo_workspace_provisioner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_filesystem_port.dart';

class _FakeIsolation implements RepoIsolationPort {
  final List<String> destroyed = [];
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
  }) async =>
      RepoIsolationResult(
        path: '$destParentDir/$name',
        backend: RepoIsolationBackend.rift,
      );

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async =>
      destroyed.add(path);
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

RepoWorkspaceProvisioner _build({
  required IsolatedRepoRepository registry,
  required _FakeIsolation isolation,
  List<Repo> repos = const [],
}) =>
    RepoWorkspaceProvisioner(
      filesystem: FakeFilesystemPort(),
      isolation: isolation,
      registry: registry,
      workspaces: _FakeWorkspaces(repos),
      githubToken: () async => '',
      branchTemplate: () => '{type}/{ticket-key}-{slug}',
    );

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

void main() {
  group('RepoWorkspaceProvisioner', () {
    test('returns the fallback dir when the workspace has no linked repos', () async {
      final p = _build(registry: _FakeRegistry(), isolation: _FakeIsolation());
      final dir = await p.ensureConversationWorkspace(
        workspaceId: 'w-1',
        channelId: 'ch',
        fallbackDir: '/agent/dir',
      );
      expect(dir, '/agent/dir');
    });

    test('returns the fallback dir when workspace/channel is empty', () async {
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
  });
}
