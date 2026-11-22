import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_server_core/src/catalog/notification_feed_visibility.dart';
import 'package:cc_server_core/src/catalog/pr_data_gate.dart'
    show SpaceReadGate;
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';
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
    seq: 0,
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
            prVisibleRepoIds: {'repo-api'},
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
    'a PR-derived row needs its repo in the viewer\'s PR visibility',
    () async {
      NotificationFeedItem row(
        String id,
        String method,
        Map<String, dynamic> p,
      ) => NotificationFeedItem(
        id: id,
        workspaceId: 'ws-a',
        method: method,
        params: p,
        seq: 0,
        createdAt: DateTime.utc(2026, 10, 16),
      );
      final items = [
        // Granted, but the viewer's own forge sign-in cannot read acme/api.
        row('pr', 'notifications/pr_review_requested', {
          'repo_owner': 'Acme',
          'repo_name': 'api',
        }),
        row('stale', 'notifications/review_stale', {'repo_id': 'repo-api'}),
        row('external', 'notifications/external_pr_merged', {
          'repo_owner': 'Acme',
          'repo_name': 'api',
        }),
        // Not PR data: the grant alone decides, as before.
        row('rig', 'notifications/rig_reaped', {'repo_id': 'repo-api'}),
        // A published agent PR by lifecycle id names no repository.
        row('merged', 'notifications/pr_merged', {'pr_id': 'pr-1'}),
        // Visible on both counts.
        row('web', 'notifications/pr_review_requested', {
          'repo_owner': 'Acme',
          'repo_name': 'web',
        }),
      ];
      final result = await filterNotificationFeedItems(
        workspaceId: 'ws-a',
        userId: 'user-a',
        items: items,
        isMember: true,
        repoIdsByCoordinate: {'acme/api': 'repo-api', 'acme/web': 'repo-web'},
        readableRepoIds: {'repo-api', 'repo-web'},
        prVisibleRepoIds: {'repo-web'},
        canReadSpace: (_) async => true,
      );
      expect(result.map((r) => r.id), ['rig', 'merged', 'web']);
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
        prVisibleRepoIds: {'repo-api'},
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
    // `room-secret` exposes `repo-api`: the space read gate withholds it
    // while the viewer may not read that repository.
    final spaceRead = _SpaceRead(
      (_) async =>
          (members.grants['repo-api'] ?? RepoGrantLevel.none).allowsRead
          ? const {}
          : const {'room-secret'},
    );
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
          spaceRead: spaceRead,
          prVisibility: RepoVisibility(
            visible: {workspaces.repos.single.id: workspaces.repos.single},
            hidden: const {},
          ),
        );

    expect(await visible(), isEmpty);
    members.grants['repo-api'] = RepoGrantLevel.read;
    expect((await visible()).map((row) => row.id), ['repo', 'space']);
    members.grants.clear();
    expect(await visible(), isEmpty);
    members.member = null;
    expect(await visible(), isEmpty);
  });

  test(
    'the space read gate alone decides a space row, admins included',
    () async {
      final now = DateTime.utc(2026, 11, 10);
      final members = _Members()
        ..member = WorkspaceMember(
          id: 'membership-admin',
          workspaceId: 'ws-a',
          userId: 'admin-a',
          role: WorkspaceRole.admin,
          joinedAt: now,
        );
      var withheld = <String>{'room-secret'};
      Future<List<String>> visible() async => [
        for (final row in await visibleNotificationItemsForUser(
          workspaceId: 'ws-a',
          userId: 'admin-a',
          items: [
            item('space', {'space_id': 'room-secret'}),
            item('open', {'space_id': 'room-open'}),
          ],
          members: members,
          workspaces: _Workspaces(const []),
          spaceRead: _SpaceRead((_) async => withheld),
          prVisibility: RepoVisibility.empty,
        ))
          row.id,
      ];

      expect(await visible(), ['open']);
      withheld = {};
      expect(await visible(), ['space', 'open']);
    },
  );
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

class _SpaceRead implements SpaceReadGate {
  _SpaceRead(this._unreadable);
  final Future<Set<String>> Function(String userId) _unreadable;

  @override
  Future<void> require(
    String workspaceId,
    String userId,
    String spaceId,
  ) async {}

  @override
  Future<Set<String>> unreadable(String workspaceId, String userId) =>
      _unreadable(userId);

  @override
  Future<List<String>> exposedBy(String workspaceId, String? spaceId) async =>
      const [];
}
