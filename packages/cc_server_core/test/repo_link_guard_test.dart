import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart' show RepoOpContext;
import 'package:cc_server_core/src/catalog/repo_link_guard.dart';
import 'package:test/test.dart';

/// `repos.upsert` and `repos.addFromPath` let only a workspace admin make a
/// forge link (a new one or a retargeted one); everyday edits stay open.
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

  test('a new or retargeted forge remote is a link', () {
    expect(isNewForgeLink(null, repo()), isTrue);
    expect(isNewForgeLink(repo(), repo(owner: 'other')), isTrue);
    expect(isNewForgeLink(repo(), repo(name: 'web')), isTrue);
  });

  test('renaming or moving a link already made is not', () {
    expect(isNewForgeLink(repo(), repo(owner: 'ACME', path: '/moved')), false);
    expect(isNewForgeLink(null, repo(owner: '', name: '')), isFalse);
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
}
