import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/server_notice_ops.dart';
import 'package:cc_server_core/src/workspace_storage_alerts.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The server owner hears once, durably, that a workspace's database turned
/// read-only, and the notice closes when the workspace is restored.
void main() {
  late GlobalDatabase global;
  late DaoServerNoticeRepository notices;
  late List<String> logged;
  late WorkspaceStorageAlerts alerts;

  setUp(() {
    global = createTestGlobalDatabase();
    notices = DaoServerNoticeRepository(global);
    logged = [];
    alerts = WorkspaceStorageAlerts(notices, log: logged.add);
  });

  tearDown(() async {
    await alerts.dispose();
    await global.close();
  });

  test('a damaged workspace notifies the owner once', () async {
    expect(await alerts.report('ws-1', 'page 4: btreeInitPage error'), isTrue);
    // The next process meets the same file and reports it again.
    final restarted = WorkspaceStorageAlerts(notices, log: logged.add);
    expect(
      await restarted.report('ws-1', 'page 4: btreeInitPage error'),
      isFalse,
    );

    final open = await notices.open();
    expect(open.single.subject, 'ws-1');
    expect(open.single.detail, contains('btreeInitPage'));
    expect(logged, hasLength(1));
  });

  test('a restore closes the notice', () async {
    final bus = DomainEventBus();
    addTearDown(bus.dispose);
    alerts.listen(bus);
    await alerts.report('ws-1', 'damaged');

    bus.publish(
      WorkspaceRestored(workspaceId: 'ws-1', occurredAt: DateTime(2026, 6, 1)),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(await notices.open(), isEmpty);
    expect(await alerts.report('ws-1', 'damaged again'), isTrue);
  });

  test('says which workspace changed state when it turns read-only and '
      'when it is restored', () async {
    final bus = DomainEventBus();
    addTearDown(bus.dispose);
    alerts.listen(bus);
    final changed = <String>[];
    final sub = alerts.changes.listen(changed.add);
    addTearDown(sub.cancel);

    await alerts.report('ws-1', 'damaged');
    await pumpEventQueue();
    expect(changed, ['ws-1']);

    // The next process meets the same file: no new notice for the owner,
    // but its members' clients have to hear it again.
    final restarted = WorkspaceStorageAlerts(notices);
    addTearDown(restarted.dispose);
    final again = <String>[];
    final restartedSub = restarted.changes.listen(again.add);
    addTearDown(restartedSub.cancel);
    expect(await restarted.report('ws-1', 'damaged'), isFalse);
    await pumpEventQueue();
    expect(again, ['ws-1']);

    bus.publish(
      WorkspaceRestored(workspaceId: 'ws-1', occurredAt: DateTime(2026, 6, 1)),
    );
    await pumpEventQueue();
    expect(changed, ['ws-1', 'ws-1']);
  });

  test('server.notices lists them for the server owner only', () async {
    await alerts.report('ws-1', 'damaged');
    final op = buildServerNoticeOps(notices: notices).single;

    expect(op.serverAuthority, ServerAuthority.serverOwner);
    final result = await op.handler(
      const RepoOpContext(
        args: {},
        workspaceId: null,
        deviceId: 'd-1',
        userId: 'owner',
      ),
    );
    expect(result['notices'], [containsPair('kind', 'workspace_read_only')]);
    expect(buildServerNoticeOps(notices: null), isEmpty);
  });
}
