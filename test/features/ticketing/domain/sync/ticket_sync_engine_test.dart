import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_field_conflict_policy.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_engine.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_link.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'sync_test_fakes.dart';

void main() {
  late FakeTicketRepository tickets;
  late FakeSyncConfigRepository configs;
  late FakeSyncLinkRepository links;
  late FakeSyncLogRepository logs;
  const ws = 'ws-1';
  final now = DateTime.utc(2026, 1, 1);
  var seq = 0;

  TicketSyncEngine engineWith(List<dynamic> adapters) => TicketSyncEngine(
    adapters: adapters.cast(),
    repository: tickets,
    configRepository: configs,
    linkRepository: links,
    logRepository: logs,
    now: () => now,
    newId: () => 'id-${++seq}',
  );

  Ticket localTicket({
    String id = 't1',
    String title = 'Fix login',
    TicketStatus status = TicketStatus.open,
    TicketOriginKind origin = TicketOriginKind.manual,
  }) => Ticket(
    id: id,
    workspaceId: ws,
    title: title,
    status: status,
    originKind: origin,
    createdAt: now,
    updatedAt: now,
  );

  Future<void> enableVendor(
    String vendor, {
    SyncDirection direction = SyncDirection.bidirectional,
    TicketFieldConflictPolicy policy = const TicketFieldConflictPolicy(),
  }) => configs.upsert(
    TicketSyncConfig(
      id: 'cfg-$vendor',
      workspaceId: ws,
      vendor: vendor,
      direction: direction,
      fieldPolicy: policy,
      createdAt: now,
      updatedAt: now,
    ),
  );

  setUp(() {
    tickets = FakeTicketRepository();
    configs = FakeSyncConfigRepository();
    links = FakeSyncLinkRepository();
    logs = FakeSyncLogRepository();
    seq = 0;
  });

  group('pushTicket', () {
    test('pushes to an enabled vendor and persists a link', () async {
      await enableVendor('linear');
      final adapter = FakeSyncAdapter('linear');
      final engine = engineWith([adapter]);
      final ticket = localTicket();
      await tickets.insert(ticket);

      final summary = await engine.pushTicket(
        workspaceId: ws,
        ticket: ticket,
        changeType: TicketChangeType.created,
      );

      expect(summary.pushed, 1);
      expect(adapter.pushes, hasLength(1));
      expect(adapter.pushes.single.change, TicketChangeType.created);
      final link = await links.forTicketVendor(ws, 't1', 'linear');
      expect(link, isNotNull);
      expect(link!.externalId, isNotEmpty);
      expect(link.lastDirection, SyncDirection.push);
      expect(
        logs.entries.where((e) => e.outcome == SyncOutcome.ok),
        hasLength(1),
      );
    });

    test('skips a pull-only vendor', () async {
      await enableVendor('linear', direction: SyncDirection.pull);
      final adapter = FakeSyncAdapter('linear');
      final engine = engineWith([adapter]);
      final ticket = localTicket();
      await tickets.insert(ticket);

      final summary = await engine.pushTicket(
        workspaceId: ws,
        ticket: ticket,
        changeType: TicketChangeType.updated,
      );

      expect(summary.pushed, 0);
      expect(summary.skipped, 1);
      expect(adapter.pushes, isEmpty);
    });

    test('fans out to multiple vendors and records a failure', () async {
      await enableVendor('linear');
      await enableVendor('jira');
      final linear = FakeSyncAdapter('linear');
      final jira = FakeSyncAdapter('jira', failOnPush: true);
      final engine = engineWith([linear, jira]);
      final ticket = localTicket();
      await tickets.insert(ticket);

      final summary = await engine.pushTicket(
        workspaceId: ws,
        ticket: ticket,
        changeType: TicketChangeType.created,
      );

      expect(summary.pushed, 1);
      expect(summary.failed, 1);
      expect(linear.pushes, hasLength(1));
      expect(
        logs.entries.where((e) => e.outcome == SyncOutcome.failed),
        hasLength(1),
      );
    });

    test('reuses an existing external id on a second push', () async {
      await enableVendor('linear');
      final adapter = FakeSyncAdapter('linear');
      final engine = engineWith([adapter]);
      final ticket = localTicket();
      await tickets.insert(ticket);

      await engine.pushTicket(
        workspaceId: ws,
        ticket: ticket,
        changeType: TicketChangeType.created,
      );
      final firstId = (await links.forTicketVendor(
        ws,
        't1',
        'linear',
      ))!.externalId;
      await engine.pushTicket(
        workspaceId: ws,
        ticket: ticket,
        changeType: TicketChangeType.statusChanged,
      );
      final secondId = (await links.forTicketVendor(
        ws,
        't1',
        'linear',
      ))!.externalId;

      expect(secondId, firstId);
      expect(links.store.where((l) => l.ticketId == 't1'), hasLength(1));
    });
  });

  group('pullNow (§188 manual sync)', () {
    test('pulls + applies deltas for an enabled pull-capable vendor', () async {
      await enableVendor('linear');
      final adapter = FakeSyncAdapter('linear')
        ..pulls = [
          const TicketSyncDelta(
            externalId: 'lin-9',
            externalKey: 'ENG-9',
            title: 'Filed in Linear',
            status: TicketStatus.open,
            rawStatus: 'Todo',
            url: 'https://linear.app/x/ENG-9',
          ),
        ];
      final engine = engineWith([adapter]);

      final summary = await engine.pullNow(workspaceId: ws);

      expect(summary.created, 1);
      expect(tickets.store.values, hasLength(1));
      expect(tickets.store.values.single.title, 'Filed in Linear');
    });

    test('skips a push-only vendor (no pull applied)', () async {
      await enableVendor('linear', direction: SyncDirection.push);
      final adapter = FakeSyncAdapter('linear')
        ..pulls = [
          const TicketSyncDelta(
            externalId: 'lin-x',
            externalKey: 'ENG-X',
            title: 'should not import',
            status: TicketStatus.open,
            rawStatus: 'Todo',
            url: 'https://linear.app/x/ENG-X',
          ),
        ];
      final engine = engineWith([adapter]);

      final summary = await engine.pullNow(workspaceId: ws);

      expect(summary.created, 0);
      expect(summary.skipped, greaterThanOrEqualTo(1));
      expect(tickets.store.values, isEmpty);
    });
  });

  group('applyPull', () {
    test('creates a new CC ticket for a vendor-created ticket', () async {
      await enableVendor('linear');
      final engine = engineWith([FakeSyncAdapter('linear')]);

      final summary = await engine.applyPull(
        workspaceId: ws,
        vendor: 'linear',
        deltas: [
          const TicketSyncDelta(
            externalId: 'lin-1',
            externalKey: 'ENG-123',
            title: 'Created in Linear',
            status: TicketStatus.inProgress,
            rawStatus: 'In Progress',
            url: 'https://linear.app/x/ENG-123',
          ),
        ],
      );

      expect(summary.created, 1);
      expect(tickets.store.values, hasLength(1));
      final created = tickets.store.values.single;
      expect(created.title, 'Created in Linear');
      expect(created.originKind, TicketOriginKind.externalSync);
      expect(created.status, TicketStatus.inProgress);
      final link = await links.byExternalId(ws, 'linear', 'lin-1');
      expect(link, isNotNull);
      expect(link!.ticketId, created.id);
      expect(link.externalKey, 'ENG-123');
    });

    test('mirror-updates an existing ticket when vendor wins', () async {
      await enableVendor(
        'linear',
        policy: TicketFieldConflictPolicy.vendorOwned,
      );
      final engine = engineWith([FakeSyncAdapter('linear')]);
      final ticket = localTicket(status: TicketStatus.open);
      await tickets.insert(ticket);
      await links.upsert(_linkFor(ws, 't1', 'linear', 'lin-1'));

      final summary = await engine.applyPull(
        workspaceId: ws,
        vendor: 'linear',
        deltas: [
          const TicketSyncDelta(
            externalId: 'lin-1',
            status: TicketStatus.done,
            rawStatus: 'Done',
          ),
        ],
      );

      expect(summary.updated, 1);
      expect(tickets.store['t1']!.status, TicketStatus.done);
    });

    test('protects a CC-owned field (agent edit wins)', () async {
      // Default policy = cc wins.
      await enableVendor('linear');
      final engine = engineWith([FakeSyncAdapter('linear')]);
      final ticket = localTicket(
        title: 'Agent title',
        status: TicketStatus.open,
      );
      await tickets.insert(ticket);
      await links.upsert(_linkFor(ws, 't1', 'linear', 'lin-1'));

      final summary = await engine.applyPull(
        workspaceId: ws,
        vendor: 'linear',
        deltas: [
          const TicketSyncDelta(
            externalId: 'lin-1',
            title: 'Vendor title',
            status: TicketStatus.done,
          ),
        ],
      );

      expect(summary.skipped, 1);
      expect(tickets.store['t1']!.title, 'Agent title');
      expect(tickets.store['t1']!.status, TicketStatus.open);
    });

    test('drops a re-delivered event by dedupe key', () async {
      await enableVendor('linear');
      final engine = engineWith([FakeSyncAdapter('linear')]);

      const delta = TicketSyncDelta(
        externalId: 'lin-9',
        externalKey: 'ENG-9',
        title: 'Once',
        dedupeKey: 'delivery-abc',
      );
      await engine.applyPull(
        workspaceId: ws,
        vendor: 'linear',
        deltas: [delta],
      );
      final second = await engine.applyPull(
        workspaceId: ws,
        vendor: 'linear',
        deltas: [delta],
      );

      expect(second.deduplicated, 1);
      expect(tickets.store.values, hasLength(1));
    });

    test('skips when no enabled config exists', () async {
      final engine = engineWith([FakeSyncAdapter('linear')]);
      final summary = await engine.applyPull(
        workspaceId: ws,
        vendor: 'linear',
        deltas: const [TicketSyncDelta(externalId: 'x')],
      );
      expect(summary.skipped, 1);
      expect(tickets.store, isEmpty);
    });
  });
}

TicketSyncLink _linkFor(
  String ws,
  String ticketId,
  String vendor,
  String externalId,
) => TicketSyncLink(
  id: const Uuid().v4(),
  workspaceId: ws,
  ticketId: ticketId,
  vendor: vendor,
  externalId: externalId,
);
