import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_server_core/src/backup/workspace_restore_invalidation.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';
import 'package:cc_server_core/src/identity/caching_workspace_membership_repository.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The membership rows as the database holds them, which a restore rewrites
/// without going through the caching repository.
class _Rows implements WorkspaceMembershipRepository {
  final roles = <String, WorkspaceRole>{};
  int reads = 0;

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async {
    reads++;
    final role = roles['$workspaceId/$userId'];
    return role == null
        ? null
        : WorkspaceMember(
            id: 'm-$userId',
            workspaceId: workspaceId,
            userId: userId,
            role: role,
            joinedAt: DateTime.utc(2026, 11),
          );
  }

  @override
  Future<List<WorkspaceMember>> getForWorkspace(String workspaceId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

void main() {
  late DomainEventBus bus;
  late _Rows rows;
  late CachingWorkspaceMembershipRepository members;

  setUp(() {
    bus = DomainEventBus();
    rows = _Rows()..roles['ws-1/u-1'] = WorkspaceRole.admin;
    members = CachingWorkspaceMembershipRepository(rows);
    invalidateOnAuthorityRewrite(eventBus: bus, memberships: members);
  });

  tearDown(() => bus.dispose());

  test('a restored workspace is not answered from the cached roles', () async {
    expect((await members.getMember('ws-1', 'u-1'))?.role, WorkspaceRole.admin);
    // The restore demoted the admin in the file itself.
    rows.roles['ws-1/u-1'] = WorkspaceRole.member;
    expect(
      (await members.getMember('ws-1', 'u-1'))?.role,
      WorkspaceRole.admin,
      reason: 'the cache has not heard of the restore yet',
    );

    bus.publish(
      WorkspaceRestored(workspaceId: 'ws-1', occurredAt: DateTime.utc(2026)),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      (await members.getMember('ws-1', 'u-1'))?.role,
      WorkspaceRole.member,
    );
  });

  test('an accepted import hold is not answered from the cached roles '
      'either', () async {
    rows.roles['ws-1/u-1'] = WorkspaceRole.member;
    expect(
      (await members.getMember('ws-1', 'u-1'))?.role,
      WorkspaceRole.member,
    );
    rows.roles['ws-1/u-1'] = WorkspaceRole.admin;

    bus.publish(
      ImportedAuthorityAccepted(
        workspaceId: 'ws-1',
        kind: 'membership_role',
        occurredAt: DateTime.utc(2026),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final readsBefore = rows.reads;
    expect((await members.getMember('ws-1', 'u-1'))?.role, WorkspaceRole.admin);
    expect(rows.reads, readsBefore + 1);
  });

  group('repository access records', () {
    late RepoAccessRegistry registry;

    /// A registry that has loaded one unreachable repository, over a
    /// database that is then replaced by an empty one, as a restore does.
    Future<void> restoreOver() async {
      final before = createTestDatabase(workspaceId: 'ws-1');
      final after = createTestDatabase(workspaceId: 'ws-1');
      addTearDown(before.close);
      addTearDown(after.close);
      var current = before;
      registry = RepoAccessRegistry(cacheFor: (_) => current.cacheDao);
      invalidateOnAuthorityRewrite(
        eventBus: bus,
        memberships: members,
        repoAccess: registry,
      );
      await registry.record(
        'ws-1',
        forge: ForgeHost.github,
        owner: 'acme',
        name: 'widgets',
        state: RepoAccessState.appNotInstalled,
      );
      current = after;
    }

    test('are re-read from the restored file, and watchers hear it', () async {
      await restoreOver();
      final frames = <List<String>>[];
      final watch = registry
          .watch('ws-1')
          .listen((issues) => frames.add([for (final i in issues) i.fullName]));
      addTearDown(watch.cancel);
      await Future<void>.delayed(Duration.zero);
      expect(frames, [
        ['acme/widgets'],
      ]);

      bus.publish(
        WorkspaceRestored(workspaceId: 'ws-1', occurredAt: DateTime.utc(2026)),
      );
      await pumpEventQueue();

      expect(await registry.issues('ws-1'), isEmpty);
      expect(frames.last, isEmpty);
    });

    test('stay as they are when a held grant is accepted', () async {
      await restoreOver();

      bus.publish(
        ImportedAuthorityAccepted(
          workspaceId: 'ws-1',
          kind: 'membership_role',
          occurredAt: DateTime.utc(2026),
        ),
      );
      await pumpEventQueue();

      expect((await registry.issues('ws-1')).single.fullName, 'acme/widgets');
    });
  });
}
