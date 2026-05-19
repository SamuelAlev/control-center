import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/activity_log_persister.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The audit trail's write path.
///
/// `activity_log` had a table, a DAO, a retention sweep and a read path — and
/// no writer at all: `ActivityLogPersister` was defined and never constructed,
/// so the client's entity timeline read a table nothing ever wrote to. These
/// pin both halves of the fix: that events are persisted, and that each one
/// lands in ITS OWN workspace's database rather than in whichever workspace
/// happened to resolve a DAO first.
Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late DomainEventBus bus;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late ActivityLogPersister persister;
  late List<String> registered;

  setUp(() async {
    bus = DomainEventBus();
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    registered = ['ws-a', 'ws-b'];
    for (final id in registered) {
      await seedTestWorkspace(global, dbs, id);
    }
    persister = ActivityLogPersister(
      eventBus: bus,
      dbs: dbs,
      workspaceExists: (id) async => registered.contains(id),
    )..start();
  });

  tearDown(() async {
    persister.dispose();
    await dbs.closeAll();
    await global.close();
  });

  Future<List<ActivityLogTableData>> rowsIn(String workspaceId) =>
      dbs.of(workspaceId).activityLogDao.watchRecent(workspaceId).first;

  test('persists an activity event into its own workspace', () async {
    ActivityLogger(eventBus: bus).logUserAction(
      action: 'created',
      entityType: 'ticket',
      entityId: 't-1',
      workspaceId: 'ws-a',
    );
    await _pump();

    final rows = await rowsIn('ws-a');
    expect(rows, hasLength(1));
    expect(rows.single.action, 'created');
    expect(rows.single.entityType, 'ticket');
    expect(rows.single.entityId, 't-1');
    expect(rows.single.workspaceId, 'ws-a');
    expect(rows.single.actorType, 'user');
  });

  test(
    'each workspace gets its own rows — no leak through a cached DAO',
    () async {
      // The regression this shape exists for: the first version took ONE
      // `ActivityLogDao` in its constructor, so every workspace's audit rows
      // landed in whichever workspace resolved it first, with a `workspace_id`
      // column claiming otherwise.
      final logger = ActivityLogger(eventBus: bus)
        ..logUserAction(
          action: 'created',
          entityType: 'ticket',
          entityId: 'a-1',
          workspaceId: 'ws-a',
        );
      logger.logUserAction(
        action: 'deleted',
        entityType: 'channel',
        entityId: 'b-1',
        workspaceId: 'ws-b',
      );
      await _pump();

      final a = await rowsIn('ws-a');
      final b = await rowsIn('ws-b');
      expect(a.map((r) => r.entityId), ['a-1']);
      expect(b.map((r) => r.entityId), ['b-1']);
    },
  );

  test('an event naming no workspace is dropped, not misfiled', () async {
    bus.publish(
      ActivityLogged(
        id: 'evt-1',
        actorType: 'system',
        action: 'booted',
        entityType: 'server',
        occurredAt: DateTime.now(),
      ),
    );
    await _pump();

    for (final id in registered) {
      expect(
        await rowsIn(id),
        isEmpty,
        reason: 'a workspace-less event must not be written to any workspace',
      );
    }
  });

  test('an unregistered workspace is refused', () async {
    ActivityLogger(eventBus: bus).logUserAction(
      action: 'created',
      entityType: 'ticket',
      entityId: 'ghost-1',
      workspaceId: 'ws-deleted',
    );
    await _pump();

    // `of()` opens — and therefore CREATES — the named file, so a late event
    // from a deleted workspace would otherwise resurrect it as a ghost
    // database carrying exactly one audit row.
    expect(dbs.openIds, isNot(contains('ws-deleted')));
  });

  test('dispose stops persisting', () async {
    persister.dispose();
    ActivityLogger(eventBus: bus).logUserAction(
      action: 'created',
      entityType: 'ticket',
      entityId: 'after-dispose',
      workspaceId: 'ws-a',
    );
    await _pump();

    expect(await rowsIn('ws-a'), isEmpty);
  });
}
