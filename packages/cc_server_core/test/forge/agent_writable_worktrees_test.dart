import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_server_core/src/forge/agent_push_repo_check.dart';
import 'package:test/test.dart';

final class _Members implements WorkspaceMembershipRepository {
  _Members(this.roles, this.grants);

  final Map<String, WorkspaceRole> roles;
  final Map<String, Map<String, RepoGrantLevel>> grants;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async {
    final role = roles[userId];
    return role == null
        ? null
        : WorkspaceMember(
            id: 'm-$userId',
            workspaceId: workspaceId,
            userId: userId,
            role: role,
            joinedAt: DateTime.utc(2026),
          );
  }

  @override
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async => grants[userId] ?? const {};
}

final class _Worktrees implements IsolatedRepoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => workspaceId == 'ws' && spaceId == 'space'
      ? [_worktree('r-api', 'api'), _worktree('r-web', 'web')]
      : const [];
}

IsolatedRepo _worktree(String repoId, String name) => IsolatedRepo(
  id: 'iso-$name',
  workspaceId: 'ws',
  spaceId: 'space',
  repoId: repoId,
  path: '/data/ws/spaces/space/repos/$name',
  branch: 'cc/$name',
  backend: RepoIsolationBackend.rift,
  sourcePath: '/src/$name',
  createdAt: DateTime.utc(2026),
);

/// Changing a worktree takes the same grant as pushing its repository, asked
/// of the run's accountable human.
void main() {
  final members = _Members(
    {
      'writer': WorkspaceRole.member,
      'reader': WorkspaceRole.member,
      'admin': WorkspaceRole.admin,
      'owner': WorkspaceRole.owner,
    },
    {
      'writer': {'r-api': RepoGrantLevel.write, 'r-web': RepoGrantLevel.read},
      'reader': {'r-api': RepoGrantLevel.read, 'r-web': RepoGrantLevel.read},
    },
  );
  final asked = <String?>[];
  final writable = agentWritableWorktrees(
    worktrees: _Worktrees(),
    members: members,
    // As GitHubClients.accountableHuman: the acting person while a member,
    // else the workspace owner.
    accountableHuman: (workspaceId, {actingUserId}) async {
      asked.add(actingUserId);
      if (actingUserId != null) {
        return members.roles.containsKey(actingUserId) ? actingUserId : null;
      }
      return 'owner';
    },
  );

  setUp(asked.clear);

  test('write on one repository and read on the other writes only the '
      'first', () async {
    expect(await writable('ws', 'space', 'writer'), [
      '/data/ws/spaces/space/repos/api',
    ]);
  });

  test('a read grant writes nothing', () async {
    expect(await writable('ws', 'space', 'reader'), isEmpty);
  });

  test('a workspace admin writes every worktree', () async {
    expect(await writable('ws', 'space', 'admin'), [
      '/data/ws/spaces/space/repos/api',
      '/data/ws/spaces/space/repos/web',
    ]);
  });

  test('a run nobody asked for is held to the accountable human the push '
      'gateway resolves', () async {
    expect(await writable('ws', 'space', null), hasLength(2));
    expect(asked, [null]);
  });

  test('no accountable human, nothing writable', () async {
    expect(await writable('ws', 'space', 'stranger'), isEmpty);
  });
}
