import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_server_core/src/catalog/notification_feed_visibility.dart';
import 'package:test/test.dart';

void main() {
  NotificationFeedItem item(
    String id,
    Map<String, dynamic> params, {
    String workspaceId = 'ws-a',
  }) => NotificationFeedItem(
    id: id,
    workspaceId: workspaceId,
    method: 'notifications/pr_review_requested',
    params: params,
    createdAt: DateTime.utc(2026, 10, 16),
  );

  test(
    'membership, recipient, linked repo grants and space grants gate rows',
    () async {
      final items = [
        item('granted', {'repo_owner': 'Acme', 'repo_name': 'api'}),
        item('ungranted', {'repo_owner': 'Acme', 'repo_name': 'private'}),
        item('unlinked', {'repo_owner': 'Elsewhere', 'repo_name': 'api'}),
        item('mismatched', {
          'repo_id': 'repo-api',
          'repo_owner': 'Acme',
          'repo_name': 'private',
        }),
        item('other-user', {'for_user_id': 'someone-else'}),
        item('permitted-space', {'space_id': 'room-ok'}),
        item('denied-space', {'space_id': 'room-secret'}),
        item('other-workspace', {}, workspaceId: 'ws-b'),
      ];
      var spaceReads = 0;
      Future<List<NotificationFeedItem>> visible({required bool member}) =>
          filterNotificationFeedItems(
            workspaceId: 'ws-a',
            userId: 'user-a',
            items: items,
            isMember: member,
            repoIdsByCoordinate: {
              'acme/api': 'repo-api',
              'acme/private': 'repo-private',
            },
            readableRepoIds: {'repo-api'},
            canReadSpace: (spaceId) async {
              spaceReads++;
              return spaceId == 'room-ok';
            },
          );

      expect((await visible(member: true)).map((row) => row.id), [
        'granted',
        'permitted-space',
      ]);
      expect(spaceReads, 2);
      expect(await visible(member: false), isEmpty);
    },
  );

  test(
    'row addressed to another principal never becomes visible with repo grant',
    () async {
      final result = await filterNotificationFeedItems(
        workspaceId: 'ws-a',
        userId: 'user-a',
        items: [
          item('other', {'repo_id': 'repo-api', 'for_user_id': 'user-b'}),
        ],
        isMember: true,
        repoIdsByCoordinate: {'acme/api': 'repo-api'},
        readableRepoIds: {'repo-api'},
        canReadSpace: (_) async => true,
      );
      expect(result, isEmpty);
    },
  );

  test('shared live resolver denies revoked repo and space grants', () async {
    final now = DateTime.utc(2026, 10, 16);
    final members = _Members()
      ..member = WorkspaceMember(
        id: 'membership-a',
        workspaceId: 'ws-a',
        userId: 'user-a',
        role: WorkspaceRole.member,
        joinedAt: now,
      );
    final workspaces = _Workspaces([
      Repo(
        id: 'repo-api',
        name: 'Acme/api',
        path: '/repo/api',
        remoteOwner: 'Acme',
        remoteName: 'api',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    final isolated = _Isolated([
      IsolatedRepo(
        id: 'isolated-a',
        workspaceId: 'ws-a',
        spaceId: 'room-secret',
        repoId: 'repo-api',
        path: '/spaces/room-secret/repos/api',
        branch: 'test',
        backend: RepoIsolationBackend.rift,
        sourcePath: '/repo/api',
        createdAt: now,
      ),
    ]);
    final rows = [
      item('repo', {'repo_owner': 'Acme', 'repo_name': 'api'}),
      item('space', {'space_id': 'room-secret'}),
    ];
    Future<List<NotificationFeedItem>> visible() =>
        visibleNotificationItemsForUser(
          workspaceId: 'ws-a',
          userId: 'user-a',
          items: rows,
          members: members,
          workspaces: workspaces,
          isolatedRepos: isolated,
        );

    expect(await visible(), isEmpty);
    members.grants['repo-api'] = RepoGrantLevel.read;
    expect((await visible()).map((row) => row.id), ['repo', 'space']);
    members.grants.clear();
    expect(await visible(), isEmpty);
    members.member = null;
    expect(await visible(), isEmpty);
  });
}

class _Members implements WorkspaceMembershipRepository {
  WorkspaceMember? member;
  final grants = <String, RepoGrantLevel>{};

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      member?.workspaceId == workspaceId && member?.userId == userId
      ? member
      : null;

  @override
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async => Map.of(grants);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Workspaces implements WorkspaceRepository {
  _Workspaces(this.repos);
  final List<Repo> repos;

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(repos);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Isolated implements IsolatedRepoRepository {
  _Isolated(this.repos);
  final List<IsolatedRepo> repos;

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => repos
      .where(
        (repo) => repo.workspaceId == workspaceId && repo.spaceId == spaceId,
      )
      .toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
