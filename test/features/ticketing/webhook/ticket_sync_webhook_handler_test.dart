import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_engine.dart';
import 'package:cc_server_core/src/ticket_sync_webhook_handler.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/sync/sync_test_fakes.dart';

void main() {
  late FakeTicketRepository tickets;
  late FakeSyncConfigRepository configs;
  late FakeSyncLinkRepository links;
  late FakeSyncLogRepository logs;
  late DomainEventBus bus;
  late TicketSyncEngine engine;
  late TicketSyncWebhookHandler handler;
  const ws = 'ws-1';
  const secret = 'webhook-secret';

  String sign(String body) =>
      'sha256=${Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(body))}';

  const issueBody =
      '{"action":"opened","issue":{"number":789,"title":"Crash on save",'
      '"body":"repro","state":"open","html_url":"https://github.com/o/r/issues/789",'
      '"labels":[{"name":"bug"}]}}';

  setUp(() async {
    tickets = FakeTicketRepository();
    configs = FakeSyncConfigRepository();
    links = FakeSyncLinkRepository();
    logs = FakeSyncLogRepository();
    bus = DomainEventBus();
    engine = TicketSyncEngine(
      adapters: const [],
      repository: tickets,
      configRepository: configs,
      linkRepository: links,
      logRepository: logs,
      now: () => DateTime.utc(2026),
      newId: () => 'id-${tickets.store.length + links.store.length}',
    );
    handler = TicketSyncWebhookHandler(
      engine: engine,
      configRepository: configs,
      eventBus: bus,
      now: () => DateTime.utc(2026),
    );
    await configs.upsert(
      TicketSyncConfig(
        id: 'cfg',
        workspaceId: ws,
        vendor: 'github',
        vendorProjectId: 'o/r',
        webhookSecret: secret,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
  });

  test(
    'verified GitHub webhook auto-creates a CC ticket with external link',
    () async {
      final events = <ExternalTicketWebhookReceived>[];
      final sub = bus.on<ExternalTicketWebhookReceived>().listen(events.add);

      final result = await handler.handle(
        vendor: 'github',
        workspaceId: ws,
        headers: {
          'X-Hub-Signature-256': sign(issueBody),
          'X-GitHub-Delivery': 'delivery-1',
          'X-GitHub-Event': 'issues',
        },
        body: issueBody,
      );

      expect(result.statusCode, 202);
      expect(tickets.store.values, hasLength(1));
      expect(tickets.store.values.single.title, 'Crash on save');
      final link = await links.byExternalId(ws, 'github', '789');
      expect(link, isNotNull);
      expect(link!.externalKey, '#789');
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      expect(events.single.vendor, 'github');
      await sub.cancel();
    },
  );

  test('invalid signature is rejected (401) and applies nothing', () async {
    final result = await handler.handle(
      vendor: 'github',
      workspaceId: ws,
      headers: {'X-Hub-Signature-256': 'sha256=deadbeef'},
      body: issueBody,
    );
    expect(result.statusCode, 401);
    expect(tickets.store, isEmpty);
  });

  test('missing webhook secret config is rejected (401)', () async {
    await configs.upsert(
      TicketSyncConfig(
        id: 'cfg',
        workspaceId: ws,
        vendor: 'github',
        vendorProjectId: 'o/r',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    final result = await handler.handle(
      vendor: 'github',
      workspaceId: ws,
      headers: {'X-Hub-Signature-256': sign(issueBody)},
      body: issueBody,
    );
    expect(result.statusCode, 401);
  });

  test('unknown workspace/vendor config is 404', () async {
    final result = await handler.handle(
      vendor: 'github',
      workspaceId: 'other-ws',
      headers: {'X-Hub-Signature-256': sign(issueBody)},
      body: issueBody,
    );
    expect(result.statusCode, 404);
  });

  test('re-delivered event is de-duplicated (no second ticket)', () async {
    final headers = {
      'X-Hub-Signature-256': sign(issueBody),
      'X-GitHub-Delivery': 'delivery-1',
    };
    await handler.handle(
      vendor: 'github',
      workspaceId: ws,
      headers: headers,
      body: issueBody,
    );
    await handler.handle(
      vendor: 'github',
      workspaceId: ws,
      headers: headers,
      body: issueBody,
    );
    expect(tickets.store.values, hasLength(1));
  });
}
