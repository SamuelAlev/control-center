import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart' show WatchQueryContext;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/audit_log_ops.dart';
import 'package:cc_server_core/src/catalog/audit_log_pager.dart';
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// `audit.watchLog`: one table over the server trail (owner only) and the
/// trail of each workspace the caller administers, paged by keyset across
/// trails, filtered and counted per facet.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoServerAuditRepository serverAudit;
  late DaoUserActivityRepository activity;
  late DaoWorkspaceMembershipRepository members;
  late DomainEventBus bus;

  const owner = 'u-owner';
  const admin = 'u-admin';
  const member = 'u-member';

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    serverAudit = DaoServerAuditRepository(global.serverAuditDao);
    activity = DaoUserActivityRepository(dbs);
    members = DaoWorkspaceMembershipRepository(dbs);
    bus = DomainEventBus();
    await seedTestWorkspace(global, dbs, 'ws-a', name: 'Alpha');
    await seedTestWorkspace(global, dbs, 'ws-b', name: 'Beta');
    Future<void> join(String ws, String user, WorkspaceRole role) =>
        members.upsert(
          WorkspaceMember(
            id: '$ws-$user',
            workspaceId: ws,
            userId: user,
            role: role,
            joinedAt: DateTime.utc(2026),
          ),
        );
    await join('ws-a', owner, WorkspaceRole.owner);
    await join('ws-b', owner, WorkspaceRole.owner);
    await join('ws-a', admin, WorkspaceRole.admin);
    await join('ws-b', admin, WorkspaceRole.member);
    await join('ws-a', member, WorkspaceRole.member);

    // Interleaved in time: server, ws-a, ws-b, server, ws-a.
    await serverAudit.append(_server('s-1', 1, outcome: AuditOutcome.denied));
    await activity.append(_ws('a-1', 'ws-a', 2));
    await activity.append(_ws('b-1', 'ws-b', 3));
    await serverAudit.append(_server('s-2', 4));
    await activity.append(_ws('a-2', 'ws-a', 5, userId: admin));
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Stream<Map<String, dynamic>> watch(
    String userId, [
    Map<String, dynamic> args = const {},
  ]) {
    final query = buildAuditLogWatchQueries(
      serverAudit: serverAudit,
      activity: activity,
      members: members,
      workspaces: DaoWorkspaceRepository(global.workspaceRegistryDao, dbs),
      isServerOwner: (id) async => id == owner,
      prData: PrDataGate(
        reviewSpaces: _NoReviewSpaces(),
        resolve: (_, _) async => RepoVisibility.empty,
        watch: (_, _) => Stream.value(RepoVisibility.empty),
      ),
      eventBus: bus,
    ).single;
    return query.handler(
      WatchQueryContext(
        args: args,
        workspaceId: null,
        deviceId: 'd-1',
        userId: userId,
      ),
    );
  }

  List<String> ids(Map<String, dynamic> frame) => [
    for (final e in frame['entries'] as List) (e as Map)['id'] as String,
  ];

  List<String> scopeKeys(Map<String, dynamic> frame) => [
    for (final s in frame['scopes'] as List) (s as Map)['key'] as String,
  ];

  test('the owner reads the server trail and every workspace they '
      'administer, merged newest first', () async {
    final frame = await watch(owner).first;
    expect(ids(frame), ['a-2', 's-2', 'b-1', 'a-1', 's-1']);
    expect(scopeKeys(frame), ['server', 'ws:ws-a', 'ws:ws-b']);
    expect(frame['total'], 5);
    final server = (frame['entries'] as List)[1] as Map;
    expect(server['source'], 'server');
    expect(server['arg_names'], ['mode']);
    expect(server.containsKey('workspace_id'), isFalse);
    final ws = (frame['entries'] as List)[0] as Map;
    expect(ws['source'], 'ws:ws-a');
    expect(ws['workspace_id'], 'ws-a');
    expect(ws['outcome'], 'ok');
  });

  test('a workspace admin reads only the workspaces they administer, '
      'never the server trail', () async {
    final frame = await watch(admin).first;
    expect(scopeKeys(frame), ['ws:ws-a']);
    expect(ids(frame), ['a-2', 'a-1']);
    // Asking for the server trail by key does not widen what is read.
    final asked = await watch(admin, {
      'sources': ['server', 'ws:ws-b'],
    }).first;
    expect(ids(asked), isEmpty);
    expect(asked['total'], 0);
  });

  test('a plain member reads nothing', () async {
    final frame = await watch(member).first;
    expect(scopeKeys(frame), isEmpty);
    expect(ids(frame), isEmpty);
  });

  test('pages walk forward and back across trails', () async {
    final first = await watch(owner, {'limit': 2}).first;
    expect(ids(first), ['a-2', 's-2']);
    expect(first['start'], 1);
    expect(first['prev_cursor'], isNull);

    final second = await watch(owner, {
      'limit': 2,
      'cursor': first['next_cursor'],
    }).first;
    expect(ids(second), ['b-1', 'a-1']);
    expect(second['start'], 3);
    // The previous page is the first one, which has no cursor.
    expect(second['prev_cursor'], isNull);

    final third = await watch(owner, {
      'limit': 2,
      'cursor': second['next_cursor'],
    }).first;
    expect(ids(third), ['s-1']);
    expect(third['start'], 5);
    expect(third['next_cursor'], isNull);
    final back = await watch(owner, {
      'limit': 2,
      'cursor': third['prev_cursor'],
    }).first;
    expect(ids(back), ['b-1', 'a-1']);
  });

  test(
    'filters narrow the rows and facets ignore their own dimension',
    () async {
      final frame = await watch(owner, {
        'sources': ['server'],
        'outcomes': ['denied'],
      }).first;
      expect(ids(frame), ['s-1']);
      final facets = frame['facets'] as Map;
      expect(facets['outcomes'], {'ok': 1, 'denied': 1});
      expect(facets['sources'], {'server': 1, 'ws:ws-a': 0, 'ws:ws-b': 0});

      final byActor = await watch(owner, {
        'actor_ids': [admin],
      }).first;
      expect(ids(byActor), ['a-2']);
      expect((byActor['facets'] as Map)['actors'], {owner: 4, admin: 1});

      final timed = await watch(owner, {
        'time': [
          {'op': 'gt', 'at': _at(2).toIso8601String()},
          {'op': 'lte', 'at': _at(4).toIso8601String()},
        ],
      }).first;
      expect(ids(timed), ['s-2', 'b-1']);

      final searched = await watch(owner, {'query': 'tickets'}).first;
      expect(ids(searched), ['b-1']);
    },
  );

  test('a new record re-emits the page', () async {
    final frames = StreamIterator(watch(owner));
    expect(await frames.moveNext(), isTrue);
    await activity.append(_ws('b-2', 'ws-b', 6));
    expect(await frames.moveNext(), isTrue);
    expect(ids(frames.current).first, 'b-2');
    await frames.cancel();
  });

  test('a demotion drops the workspace on the next frame', () async {
    final frames = StreamIterator(watch(admin));
    expect(await frames.moveNext(), isTrue);
    expect(scopeKeys(frames.current), ['ws:ws-a']);
    await members.setRole('ws-a', admin, WorkspaceRole.member);
    bus.publish(
      WorkspaceMemberRoleChanged(
        workspaceId: 'ws-a',
        userId: admin,
        role: WorkspaceRole.member,
        occurredAt: DateTime.utc(2026),
      ),
    );
    expect(await frames.moveNext(), isTrue);
    expect(scopeKeys(frames.current), isEmpty);
    await frames.cancel();
  });

  test('a malformed filter is refused, not dropped', () async {
    await expectLater(
      watch(owner, {
        'time': [
          {'op': 'around', 'at': '2026-01-01'},
        ],
      }).first,
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      watch(owner, {
        'outcomes': ['maybe'],
      }).first,
      throwsA(isA<ValidationException>()),
    );
  });

  group('readAuditLogPage', () {
    test('an empty page past the end keeps the total', () async {
      final page = await readAuditLogPage(
        selected: [ServerAuditLogSource(serverAudit)],
        visible: [ServerAuditLogSource(serverAudit)],
        limit: 10,
        cursor: const ActivityCursor(createdAtMs: 0, id: ''),
      );
      expect(page.rows, isEmpty);
      expect(page.total, 2);
      expect(page.start, 3);
    });

    test('time conditions admit by their operator', () {
      final at = _at(3);
      bool admits(AuditTimeOperator op, int minute) =>
          AuditTimeCondition(op: op, at: at).admits(_at(minute));
      expect(admits(AuditTimeOperator.atOrAfter, 3), isTrue);
      expect(admits(AuditTimeOperator.after, 3), isFalse);
      expect(admits(AuditTimeOperator.before, 3), isFalse);
      expect(admits(AuditTimeOperator.atOrBefore, 3), isTrue);
      expect(admits(AuditTimeOperator.before, 2), isTrue);
    });
  });
}

DateTime _at(int minute) => DateTime.utc(2026, 11, 10, 12, minute);

ServerAuditEntry _server(
  String id,
  int minute, {
  AuditOutcome outcome = AuditOutcome.ok,
}) => ServerAuditEntry(
  id: id,
  userId: 'u-owner',
  op: 'connect.setChoice',
  argNames: const ['mode'],
  outcome: outcome,
  createdAt: _at(minute),
);

UserActivityEntry _ws(
  String id,
  String workspaceId,
  int minute, {
  String userId = 'u-owner',
}) => UserActivityEntry(
  id: id,
  workspaceId: workspaceId,
  userId: userId,
  action: workspaceId == 'ws-b' ? 'tickets.create' : 'agents.upsert',
  createdAt: _at(minute),
);

/// No review spaces anywhere: nothing is hidden for PR reasons.
class _NoReviewSpaces implements ReviewSpaceRepository {
  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
