import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_server_core/src/forge/agent_push_repo_check.dart';
import 'package:test/test.dart';

final class _Worktrees implements IsolatedRepoRepository {
  _Worktrees(this.bySpace);

  /// `workspaceId/spaceId` → the repo ids checked out there.
  final Map<String, List<String>> bySpace;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => [
    for (final repoId in bySpace['$workspaceId/$spaceId'] ?? const <String>[])
      IsolatedRepo(
        id: 'iso-$repoId',
        workspaceId: workspaceId,
        spaceId: spaceId,
        repoId: repoId,
        path: '/data/$workspaceId/spaces/$spaceId/repos/$repoId',
        branch: 'cc/$repoId',
        backend: RepoIsolationBackend.rift,
        sourcePath: '/src/$repoId',
        createdAt: DateTime.utc(2026),
      ),
  ];
}

Repo _repo(
  String id, {
  ForgeHost forge = ForgeHost.github,
  String owner = 'acme',
  String? name,
}) => Repo(
  id: id,
  name: name ?? id,
  path: '/src/$id',
  forge: forge,
  remoteOwner: owner,
  remoteName: name ?? id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// What a run in a space works on is the server's record of the space's
/// checkouts: the linked repositories behind its worktrees, and no other.
void main() {
  final repos = agentRunSpaceRepos(
    worktrees: _Worktrees({
      'ws/space': ['shop-ui', 'api-server'],
      'ws/mixed': ['shop-ui', 'tools', 'scratch'],
      'ws/unlinked': ['gone'],
      'other/space': ['secrets'],
    }),
    linkedRepos: (workspaceId) async => switch (workspaceId) {
      'ws' => [
        _repo('shop-ui'),
        _repo('api-server'),
        // Linked to the workspace, checked out in no space asked about.
        _repo('billing'),
        _repo('tools', forge: ForgeHost.gitlab, owner: 'acme/platform'),
        // A local repository: no forge to read.
        _repo('scratch', forge: ForgeHost.local, owner: ''),
      ],
      'other' => [_repo('secrets', owner: 'other')],
      _ => const [],
    },
  );

  test('the repositories of the space\'s checkouts, in their order', () async {
    expect(await repos('ws', 'space'), [
      (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
      (forge: ForgeHost.github, owner: 'acme', name: 'api-server'),
    ]);
  });

  test('a repository linked to the workspace but not checked out in the '
      'space is not the run\'s', () async {
    final found = await repos('ws', 'space');

    expect(found.map((r) => r.name), isNot(contains('billing')));
  });

  test('every forge is named, and a repository without one is left '
      'out', () async {
    expect(await repos('ws', 'mixed'), [
      (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
      (forge: ForgeHost.gitlab, owner: 'acme/platform', name: 'tools'),
    ]);
  });

  test('a checkout whose repository is no longer linked is left out', () async {
    expect(await repos('ws', 'unlinked'), isEmpty);
  });

  test('a space is read in its own workspace only', () async {
    expect(await repos('ws', 'nowhere'), isEmpty);
    expect(await repos('nobody', 'space'), isEmpty);
    expect(await repos('other', 'space'), [
      (forge: ForgeHost.github, owner: 'other', name: 'secrets'),
    ]);
  });
}
