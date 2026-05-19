import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_field_conflict_policy.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_link.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_domain/features/ticketing/domain/writes/ticket_write_ledger.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  final now = DateTime.utc(2026);

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    // Registering a workspace is what materialises its database file; there is
    // no `workspaces` row inside a workspace database to seed any more.
    for (final ws in ['ws-1', 'ws-2']) {
      await seedTestWorkspace(global, dbs, ws, name: ws);
    }
    final ws1 = dbs.of('ws-1');
    // A ticket for the sync-link FK, in ws-1's own database.
    await ws1
        .into(ws1.ticketsTable)
        .insert(
          TicketsTableCompanion.insert(
            id: 't1',
            workspaceId: 'ws-1',
            title: 'Fix login',
          ),
        );
    // A repo for the worktree (isolated_repos) FK — `repos` is workspace-scoped
    // now, so it goes in the same file.
    await ws1
        .into(ws1.reposTable)
        .insert(
          ReposTableCompanion.insert(id: 'r1', name: 'app', path: '/repos/app'),
        );
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test('sync config round-trips and is workspace-scoped', () async {
    final repo = DaoTicketSyncConfigRepository(dbs);
    await repo.upsert(
      TicketSyncConfig(
        id: 'cfg-1',
        workspaceId: 'ws-1',
        vendor: 'linear',
        vendorProjectId: 'team-1',
        direction: SyncDirection.bidirectional,
        fieldPolicy: const TicketFieldConflictPolicy(
          perField: {TicketSyncField.status: ConflictWinner.vendor},
        ),
        webhookSecret: 'shh',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final loaded = await repo.forVendor('ws-1', 'linear');
    expect(loaded, isNotNull);
    expect(loaded!.vendorProjectId, 'team-1');
    expect(loaded.webhookSecret, 'shh');
    expect(
      loaded.fieldPolicy.winnerFor(TicketSyncField.status),
      ConflictWinner.vendor,
    );

    expect(await repo.enabledForWorkspace('ws-1'), hasLength(1));
    expect(
      await repo.forVendor('ws-2', 'linear'),
      isNull,
      reason: 'config must not leak across workspaces',
    );
  });

  test('sync link upsert is idempotent on (ws, ticket, vendor)', () async {
    final repo = DaoTicketSyncLinkRepository(dbs);
    await repo.upsert(
      TicketSyncLink(
        id: 'l1',
        workspaceId: 'ws-1',
        ticketId: 't1',
        vendor: 'linear',
        externalId: 'lin-1',
        externalKey: 'ENG-1',
      ),
    );
    // Same natural key, different id → updates the existing row, not a 2nd.
    await repo.upsert(
      TicketSyncLink(
        id: 'l2',
        workspaceId: 'ws-1',
        ticketId: 't1',
        vendor: 'linear',
        externalId: 'lin-1',
        externalKey: 'ENG-1-renamed',
        lastDirection: SyncDirection.pull,
      ),
    );

    final all = await repo.forTicket('ws-1', 't1');
    expect(all, hasLength(1));
    expect(all.single.externalKey, 'ENG-1-renamed');

    final byExt = await repo.byExternalId('ws-1', 'linear', 'lin-1');
    expect(byExt, isNotNull);
    expect(byExt!.ticketId, 't1');
    expect(byExt.lastDirection, SyncDirection.pull);
  });

  test('sync log records and dedupe lookup works', () async {
    final repo = DaoTicketSyncLogRepository(dbs);
    await repo.append(
      TicketSyncLogEntry(
        id: 'log-1',
        workspaceId: 'ws-1',
        vendor: 'github',
        direction: SyncDirection.pull,
        outcome: SyncOutcome.ok,
        dedupeKey: 'delivery-1',
        createdAt: now,
      ),
    );
    expect(await repo.hasProcessed('ws-1', 'github', 'delivery-1'), isTrue);
    expect(await repo.hasProcessed('ws-1', 'github', 'other'), isFalse);
    expect(await repo.hasProcessed('ws-2', 'github', 'delivery-1'), isFalse);
    expect(await repo.recentForWorkspace('ws-1'), hasLength(1));
  });

  test('write ledger records, finds and isolates by workspace', () async {
    final repo = DaoTicketWriteLedgerRepository(dbs);
    await repo.record(
      TicketWriteLedgerEntry(
        workspaceId: 'ws-1',
        writeId: 'w-1',
        operation: 'comment_add',
        resultJson: '{"ok":true}',
        createdAt: now,
      ),
    );
    expect(await repo.find('ws-1', 'w-1'), isNotNull);
    expect(
      await repo.find('ws-2', 'w-1'),
      isNull,
      reason: 'same writeId in another workspace is distinct',
    );
  });

  test('worktree ticket link persists the vendor link', () async {
    final ws1 = dbs.of('ws-1');
    await ws1
        .into(ws1.isolatedReposTable)
        .insert(
          IsolatedReposTableCompanion.insert(
            id: 'wt1',
            workspaceId: 'ws-1',
            channelId: 'c1',
            repoId: 'r1',
            path: '/work/ws-1/agent-a',
            branch: 'feature/x',
            sourcePath: '/repos/app',
          ),
        );
    // repos FK: insert a repo row.
    final repo = DaoWorktreeTicketLinkRepository(dbs);
    await repo.linkTicket(
      workspaceId: 'ws-1',
      worktreeId: 'wt1',
      ticketId: 't1',
      vendor: 'linear',
      externalId: 'ENG-1',
    );
    final refs = await repo.forWorkspace('ws-1');
    expect(refs, hasLength(1));
    expect(refs.single.ticketId, 't1');
    expect(refs.single.vendor, 'linear');
    expect(refs.single.externalId, 'ENG-1');
    expect(refs.single.path, '/work/ws-1/agent-a');
    expect(await repo.forWorkspace('ws-2'), isEmpty);
  });

  group('TicketSyncConfigRepository — workspace list / watch / delete', () {
    TicketSyncConfig config({
      String id = 'cfg-1',
      String workspaceId = 'ws-1',
      String vendor = 'linear',
      bool enabled = true,
    }) => TicketSyncConfig(
      id: id,
      workspaceId: workspaceId,
      vendor: vendor,
      vendorProjectId: 'team-1',
      direction: SyncDirection.bidirectional,
      fieldPolicy: const TicketFieldConflictPolicy(),
      webhookSecret: 'shh',
      createdAt: now,
      updatedAt: now,
      enabled: enabled,
    );

    test('forWorkspace lists all configs (enabled + disabled)', () async {
      final repo = DaoTicketSyncConfigRepository(dbs);
      await repo.upsert(config(id: 'cfg-1', vendor: 'linear', enabled: true));
      await repo.upsert(config(id: 'cfg-2', vendor: 'github', enabled: false));

      final all = await repo.forWorkspace('ws-1');
      expect(all.map((c) => c.vendor).toSet(), {'linear', 'github'});
    });

    test('forWorkspace is workspace-scoped', () async {
      final repo = DaoTicketSyncConfigRepository(dbs);
      await repo.upsert(config(workspaceId: 'ws-1'));
      expect(await repo.forWorkspace('ws-2'), isEmpty);
    });

    test('watchForWorkspace emits configs ordered by vendor', () async {
      final repo = DaoTicketSyncConfigRepository(dbs);
      await repo.upsert(config(id: 'z', vendor: 'zenhub'));
      await repo.upsert(config(id: 'a', vendor: 'asana'));

      final rows = await repo.watchForWorkspace('ws-1').first;
      expect(rows.map((c) => c.vendor), ['asana', 'zenhub']);
    });

    test('delete removes the config scoped to the workspace', () async {
      final repo = DaoTicketSyncConfigRepository(dbs);
      await repo.upsert(config(id: 'cfg-1'));

      // Wrong workspace → 0 rows, config survives.
      expect(await repo.delete('cfg-1', workspaceId: 'ws-2'), 0);
      expect(await repo.forVendor('ws-1', 'linear'), isNotNull);

      expect(await repo.delete('cfg-1', workspaceId: 'ws-1'), 1);
      expect(await repo.forVendor('ws-1', 'linear'), isNull);
    });

    test('delete of an unknown id deletes nothing', () async {
      final repo = DaoTicketSyncConfigRepository(dbs);
      expect(await repo.delete('no-such', workspaceId: 'ws-1'), 0);
    });
  });

  group('TicketSyncLinkRepository — update / delete', () {
    TicketSyncLink link({
      String id = 'l1',
      String ticketId = 't1',
      String vendor = 'linear',
      String externalId = 'lin-1',
      String? externalKey = 'ENG-1',
    }) => TicketSyncLink(
      id: id,
      workspaceId: 'ws-1',
      ticketId: ticketId,
      vendor: vendor,
      externalId: externalId,
      externalKey: externalKey,
    );

    test('upsert on a fresh natural key inserts via insertLink', () async {
      final repo = DaoTicketSyncLinkRepository(dbs);
      await repo.upsert(link());
      final loaded = await repo.forTicketVendor('ws-1', 't1', 'linear');
      expect(loaded, isNotNull);
      expect(loaded!.externalKey, 'ENG-1');
    });

    test('delete is workspace-scoped', () async {
      final repo = DaoTicketSyncLinkRepository(dbs);
      await repo.upsert(link(id: 'l1'));

      // Wrong workspace → 0 rows.
      expect(await repo.delete('l1', workspaceId: 'ws-2'), 0);
      expect(await repo.forTicket('ws-1', 't1'), hasLength(1));

      expect(await repo.delete('l1', workspaceId: 'ws-1'), 1);
      expect(await repo.forTicket('ws-1', 't1'), isEmpty);
    });

    test('delete of an unknown id deletes nothing', () async {
      final repo = DaoTicketSyncLinkRepository(dbs);
      expect(await repo.delete('no-such', workspaceId: 'ws-1'), 0);
    });
  });

  group('TicketSyncLogRepository — watch', () {
    TicketSyncLogEntry entry({
      String id = 'log-1',
      String vendor = 'github',
      String? dedupeKey = 'delivery-1',
    }) => TicketSyncLogEntry(
      id: id,
      workspaceId: 'ws-1',
      vendor: vendor,
      direction: SyncDirection.pull,
      outcome: SyncOutcome.ok,
      dedupeKey: dedupeKey,
      createdAt: now,
    );

    test('watchForWorkspace emits recent log entries newest-first', () async {
      final repo = DaoTicketSyncLogRepository(dbs);
      await repo.append(entry(id: 'old', vendor: 'github', dedupeKey: 'd-old'));
      await repo.append(entry(id: 'new', vendor: 'linear', dedupeKey: 'd-new'));

      final rows = await repo.watchForWorkspace('ws-1').first;
      // Both entries must be present (newest-first by createdAt).
      expect(rows.map((e) => e.vendor).toSet(), {'github', 'linear'});
    });

    test('watchForWorkspace is workspace-scoped', () async {
      final repo = DaoTicketSyncLogRepository(dbs);
      await repo.append(entry());
      final rows = await repo.watchForWorkspace('ws-2').first;
      expect(rows, isEmpty);
    });
  });
}
