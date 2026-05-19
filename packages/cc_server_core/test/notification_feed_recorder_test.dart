import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/notification_feed_recorder.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late DomainEventBus bus;
  late WorkspaceDatabaseManager dbs;
  late DaoNotificationFeedRepository repository;
  late NotificationFeedRecorder recorder;

  setUp(() {
    bus = DomainEventBus();
    dbs = createTestWorkspaceDatabases();
    repository = DaoNotificationFeedRepository(dbs);
    recorder = NotificationFeedRecorder(eventBus: bus, repository: repository)
      ..start();
  });

  tearDown(() async {
    await recorder.dispose();
    bus.dispose();
    await dbs.closeAll();
  });

  test('records one row per event into the owning workspace', () async {
    bus.publish(
      PrMerged(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        occurredAt: DateTime(2026, 8, 16),
      ),
    );
    await _pump();

    final items = await repository.watchFeed('ws-1').first;
    expect(items, hasLength(1));
    expect(items.single.method, 'notifications/pr_merged');
    expect(items.single.params['pr_id'], 'pr-1');
    expect(items.single.params['workspace_id'], 'ws-1');

    // The row landed in ws-1's file only.
    expect(await repository.watchFeed('ws-2').first, isEmpty);
  });

  test('applies the forwarding gate: un-mentioned human messages are not '
      'recorded, agent messages are', () async {
    bus.publish(
      MessageReceived(
        channelId: 'ch-1',
        messageId: 'm-1',
        senderName: 'Sam',
        contentPreview: 'hello',
        isAgentMessage: false,
        workspaceId: 'ws-1',
        occurredAt: DateTime(2026, 8, 16),
      ),
    );
    bus.publish(
      MessageReceived(
        channelId: 'ch-1',
        messageId: 'm-2',
        senderName: 'Bot',
        contentPreview: 'done',
        isAgentMessage: true,
        workspaceId: 'ws-1',
        occurredAt: DateTime(2026, 8, 16),
      ),
    );
    await _pump();

    final items = await repository.watchFeed('ws-1').first;
    expect(items, hasLength(1));
    expect(items.single.params['message_id'], 'm-2');
  });

  test('skips frames without a workspace id', () async {
    bus.publish(
      MessageReceived(
        channelId: 'ch-1',
        messageId: 'm-1',
        senderName: 'Bot',
        contentPreview: 'done',
        isAgentMessage: true,
        workspaceId: null,
        occurredAt: DateTime(2026, 8, 16),
      ),
    );
    await _pump();

    expect(await repository.watchFeed('ws-1').first, isEmpty);
  });
}
