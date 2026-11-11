import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/testing/fake_repo_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOpContext;
import 'package:cc_server_core/src/catalog/repo_link_guard.dart';
import 'package:cc_server_core/src/catalog/repo_link_ops.dart';
import 'package:test/test.dart';

/// `repos.upsert` and `repos.addFromPath` let only a workspace admin make a
/// forge link (a new one or a retargeted one); everyday edits stay open.
/// Unlinking (`repos.delete`) is an admin decision too.
void main() {
  Repo repo({String owner = 'acme', String name = 'api', String path = '/r'}) =>
      Repo(
        id: 'r1',
        name: '$owner/$name',
        path: path,
        remoteOwner: owner,
        remoteName: name,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

  RepoOpContext ctx(WorkspaceRole? role) => RepoOpContext(
    args: const {},
    workspaceId: 'ws-1',
    deviceId: 'device-1',
    userId: 'user-1',
    role: role,
  );

  test('a retargeted or emptied forge remote changes the forge identity', () {
    expect(changesForgeIdentity(repo(), repo(owner: 'other')), isTrue);
    expect(changesForgeIdentity(repo(), repo(name: 'web')), isTrue);
    expect(changesForgeIdentity(repo(), repo(owner: '', name: '')), isTrue);
    expect(
      changesForgeIdentity(repo(), repo().copyWith(forge: ForgeHost.gitlab)),
      isTrue,
    );
  });

  test('letter case or a moved path does not', () {
    expect(changesForgeIdentity(repo(), repo(owner: 'ACME')), isFalse);
    expect(changesForgeIdentity(repo(), repo(path: '/moved')), isFalse);
  });

  test('only an admin may link', () {
    for (final role in [WorkspaceRole.owner, WorkspaceRole.admin]) {
      requireRepoLinkAdmin(ctx(role));
    }
    for (final role in [
      WorkspaceRole.member,
      WorkspaceRole.guest,
      WorkspaceRole.viewer,
      null,
    ]) {
      expect(
        () => requireRepoLinkAdmin(ctx(role)),
        throwsA(isA<AuthException>()),
        reason: '$role',
      );
    }
  });

  test(
    'only an admin may unlink, and an unlink forgets its credentials',
    () async {
      final repos = FakeRepoRepository()..seed('ws-1', [repo()]);
      final forgotten = <(String, String)>[];
      final delete = buildRepoLinkOps(
        repos: repos,
        requireRepoRead: ({
          required workspaceId,
          required userId,
          required repoId,
        }) async {},
        members: null,
        pathGuard: null,
        onRepoUnlinked: (workspaceId, repo) async =>
            forgotten.add((workspaceId, repo.id)),
      ).singleWhere((op) => op.name == 'repos.delete');
      RepoOpContext as(WorkspaceRole role) => RepoOpContext(
        args: const {'repo_id': 'r1'},
        workspaceId: 'ws-1',
        deviceId: 'device-1',
        userId: 'user-1',
        role: role,
      );

      await expectLater(
        delete.handler(as(WorkspaceRole.member)),
        throwsA(isA<AuthException>()),
      );
      expect(await repos.exists('ws-1', 'r1'), isTrue);
      expect(forgotten, isEmpty);

      await delete.handler(as(WorkspaceRole.admin));
      expect(await repos.exists('ws-1', 'r1'), isFalse);
      expect(forgotten, [('ws-1', 'r1')]);
    },
  );
}
