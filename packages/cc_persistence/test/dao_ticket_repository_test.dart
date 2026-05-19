import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Constructs a [Ticket] with defaults suitable for testing.
Ticket _ticket({
  String id = 't-1',
  String workspaceId = 'ws-1',
  String title = 'Test ticket',
  TicketStatus status = TicketStatus.open,
  TicketProvider provider = TicketProvider.local,
  DateTime? createdAt,
  DateTime? updatedAt,
  int version = 0,
  String? assignedAgentId,
  String? assignedTeamId,
  String? parentTicketId,
  String? spaceId,
  String? externalKey,
  String? url,
  String? description,
  List<String> labels = const [],
  TicketPriority priority = TicketPriority.none,
  TicketOriginKind originKind = TicketOriginKind.manual,
}) {
  final now = DateTime(2026, 6, 1);
  return Ticket(
    id: id,
    workspaceId: workspaceId,
    title: title,
    status: status,
    provider: provider,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    version: version,
    assignedAgentId: assignedAgentId,
    assignedTeamId: assignedTeamId,
    parentTicketId: parentTicketId,
    spaceId: spaceId,
    externalKey: externalKey,
    url: url,
    description: description,
    labels: labels,
    priority: priority,
    originKind: originKind,
  );
}

TicketCollaborator _collaborator({
  String id = 'c-1',
  String ticketId = 't-1',
  String principalId = 'agent-1',
  DateTime? joinedAt,
}) {
  return TicketCollaborator(
    id: id,
    ticketId: ticketId,
    principalId: principalId,
    joinedAt: joinedAt ?? DateTime(2026, 6, 1),
  );
}

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoTicketRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    await seedTestWorkspace(global, dbs, 'ws-2');
    // The second argument is the GLOBAL routing table: `getByExternal` is
    // reached from a provider webhook carrying only `provider` + external key,
    // with no workspace to pick a file with, so the route resolves it.
    repo = DaoTicketRepository(dbs, global.workspaceRouteDao);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('insert + getById', () {
    test('round-trips a ticket', () async {
      await repo.insert(_ticket(id: 't-1', title: 'Hello'));
      final ticket = await repo.getById('ws-1', 't-1');
      expect(ticket, isNotNull);
      expect(ticket!.title, 'Hello');
      expect(ticket.workspaceId, 'ws-1');
    });

    test('getById returns null for unknown id', () async {
      expect(await repo.getById('ws-1', 'no-such'), isNull);
    });
  });

  group('update (optimistic concurrency)', () {
    test('update with correct expectedVersion succeeds', () async {
      await repo.insert(_ticket(id: 't-1', title: 'v1', version: 1));
      await repo.update(
        _ticket(id: 't-1', title: 'v2', version: 2),
        expectedVersion: 1,
      );
      expect((await repo.getById('ws-1', 't-1'))!.title, 'v2');
    });

    test('update with stale expectedVersion throws', () async {
      await repo.insert(_ticket(id: 't-1', title: 'v1', version: 1));
      await expectLater(
        repo.update(
          _ticket(id: 't-1', title: 'v2', version: 2),
          expectedVersion: 0,
        ),
        throwsA(isA<ConcurrencyConflictException>()),
      );
    });

    test('update on non-existent ticket throws', () async {
      await expectLater(
        repo.update(
          _ticket(id: 'no-such', title: 'Ghost', version: 1),
          expectedVersion: 0,
        ),
        throwsA(isA<ConcurrencyConflictException>()),
      );
    });
  });

  group('delete', () {
    test('deletes a ticket so getById returns null', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.delete('t-1', workspaceId: 'ws-1');
      expect(await repo.getById('ws-1', 't-1'), isNull);
    });

    test('delete with wrong workspace does not delete', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      await repo.delete('t-1', workspaceId: 'ws-2');
      expect(await repo.getById('ws-1', 't-1'), isNotNull);
    });

    test('delete cascades to collaborators', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(
        'ws-1',
        _collaborator(ticketId: 't-1', principalId: 'alice'),
      );
      await repo.delete('t-1', workspaceId: 'ws-1');
      expect(await repo.getCollaborators('ws-1', 't-1'), isEmpty);
    });
  });

  group('forAgent', () {
    test('returns tickets assigned to the agent in the workspace', () async {
      await repo.insert(
        _ticket(id: 't-1', workspaceId: 'ws-1', assignedAgentId: 'a1'),
      );
      await repo.insert(
        _ticket(id: 't-2', workspaceId: 'ws-1', assignedAgentId: 'a2'),
      );
      await repo.insert(
        _ticket(id: 't-3', workspaceId: 'ws-2', assignedAgentId: 'a1'),
      );

      final result = await repo.forAgent('ws-1', 'a1');
      expect(result.map((t) => t.id), ['t-1']);
    });
  });

  group('collaborators', () {
    test('add + get + remove', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(
        'ws-1',
        _collaborator(id: 'c1', ticketId: 't-1', principalId: 'alice'),
      );
      await repo.addCollaborator(
        'ws-1',
        _collaborator(id: 'c2', ticketId: 't-1', principalId: 'bob'),
      );

      var collabs = await repo.getCollaborators('ws-1', 't-1');
      expect(collabs.map((c) => c.principalId), containsAll(['alice', 'bob']));

      await repo.removeCollaborator('ws-1', 't-1', 'alice');
      collabs = await repo.getCollaborators('ws-1', 't-1');
      expect(collabs.map((c) => c.principalId), ['bob']);
    });
  });

  group('upsertMirror', () {
    test('inserts when no external mirror exists', () async {
      await repo.upsertMirror(
        _ticket(
          id: 't-1',
          provider: TicketProvider.linear,
          externalKey: 'ENG-1',
          title: 'Mirror',
        ),
      );
      final loaded = await repo.getByExternal(TicketProvider.linear, 'ENG-1');
      expect(loaded, isNotNull);
      expect(loaded!.title, 'Mirror');
    });

    test(
      'updates the existing mirror when (provider, externalKey) matches',
      () async {
        await repo.upsertMirror(
          _ticket(
            id: 't-1',
            provider: TicketProvider.linear,
            externalKey: 'ENG-1',
            title: 'First',
          ),
        );
        // Second mirror on the same (provider, externalKey) but new title.
        await repo.upsertMirror(
          _ticket(
            id: 'ignored',
            provider: TicketProvider.linear,
            externalKey: 'ENG-1',
            title: 'Second',
          ),
        );

        final loaded = await repo.getByExternal(TicketProvider.linear, 'ENG-1');
        expect(loaded, isNotNull);
        expect(loaded!.title, 'Second');
        expect(loaded.id, 't-1', reason: 'the mirror row is updated in place');
      },
    );

    test('treats a null externalKey as a fresh insert (no lookup)', () async {
      await repo.upsertMirror(
        _ticket(
          id: 't-1',
          provider: TicketProvider.local,
          externalKey: null,
          title: 'Local',
        ),
      );
      expect(await repo.getById('ws-1', 't-1'), isNotNull);
    });
  });

  group('getByExternal', () {
    test('returns null when the external key is unknown', () async {
      expect(
        await repo.getByExternal(TicketProvider.linear, 'missing'),
        isNull,
      );
    });

    test('returns the mirrored ticket', () async {
      await repo.upsertMirror(
        _ticket(
          id: 't-1',
          provider: TicketProvider.linear,
          externalKey: 'ENG-9',
          title: 'Synced',
        ),
      );
      final loaded = await repo.getByExternal(TicketProvider.linear, 'ENG-9');
      expect(loaded, isNotNull);
      expect(loaded!.title, 'Synced');
    });
  });

  group('childrenOf', () {
    test('lists the direct children of a parent ticket', () async {
      await repo.insert(_ticket(id: 'parent'));
      await repo.insert(_ticket(id: 'grandparent'));
      await repo.insert(_ticket(id: 'c1', parentTicketId: 'parent'));
      await repo.insert(_ticket(id: 'c2', parentTicketId: 'parent'));
      await repo.insert(_ticket(id: 'other', parentTicketId: 'grandparent'));

      final kids = await repo.childrenOf('ws-1', 'parent');
      expect(kids.map((t) => t.id).toSet(), {'c1', 'c2'});
    });

    test('is workspace-scoped', () async {
      await repo.insert(_ticket(id: 'parent'));
      // A child in ws-2 under a ws-2 parent (FK satisfied), then query ws-1.
      await repo.insert(_ticket(id: 'parent2', workspaceId: 'ws-2'));
      await repo.insert(
        _ticket(id: 'c1', workspaceId: 'ws-2', parentTicketId: 'parent2'),
      );
      expect(await repo.childrenOf('ws-1', 'parent'), isEmpty);
      expect((await repo.childrenOf('ws-2', 'parent2')).map((t) => t.id), [
        'c1',
      ]);
    });

    test('returns empty for a leaf ticket', () async {
      await repo.insert(_ticket(id: 'leaf'));
      expect(await repo.childrenOf('ws-1', 'leaf'), isEmpty);
    });
  });

  group('getById (with collaborators)', () {
    test('hydrates collaborators on the returned ticket', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(
        'ws-1',
        _collaborator(id: 'c1', ticketId: 't-1', principalId: 'alice'),
      );
      final loaded = await repo.getById('ws-1', 't-1');
      expect(loaded, isNotNull);
      expect(loaded!.collaborators, hasLength(1));
      expect(loaded.collaborators.single.principalId, 'alice');
    });
  });

  group('watch streams', () {
    test('watchForWorkspace emits only the workspace tickets', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      await repo.insert(_ticket(id: 't-2', workspaceId: 'ws-2'));

      final rows = await repo.watchForWorkspace('ws-1').first;
      expect(rows.map((t) => t.id), ['t-1']);
    });

    test('watchByStatus filters by status within the workspace', () async {
      await repo.insert(_ticket(id: 'open-1', status: TicketStatus.open));
      await repo.insert(_ticket(id: 'done-1', status: TicketStatus.done));

      final rows = await repo.watchByStatus('ws-1', TicketStatus.open).first;
      expect(rows.map((t) => t.id), ['open-1']);
    });

    test('watchByAssignee is workspace-scoped', () async {
      await repo.insert(_ticket(id: 't-1', assignedAgentId: 'a-1'));
      await repo.insert(
        _ticket(id: 't-2', workspaceId: 'ws-2', assignedAgentId: 'a-1'),
      );

      final rows = await repo.watchByAssignee('ws-1', 'a-1').first;
      expect(rows.map((t) => t.id), ['t-1']);
    });

    test('watchCollaborators emits collaborators for a ticket', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(
        'ws-1',
        _collaborator(id: 'c1', ticketId: 't-1', principalId: 'alice'),
      );

      final rows = await repo.watchCollaborators('ws-1', 't-1').first;
      expect(rows.map((c) => c.principalId), ['alice']);
    });
  });

  group('update', () {
    test('updates a ticket without an expected version check', () async {
      await repo.insert(_ticket(id: 't-1', title: 'v0', version: 0));
      await repo.update(_ticket(id: 't-1', title: 'v1', version: 1));
      expect((await repo.getById('ws-1', 't-1'))!.title, 'v1');
    });
  });

  /// [DaoTicketRepository.getByExternal] is the one read with no workspace id to
  /// pick a database file with (an inbound provider webhook carries only
  /// `provider` + external key), so it resolves the owning workspace through the
  /// GLOBAL `workspace_routes` table. These tests pin that indirection: the
  /// route has to be written with the row and die with it.
  group('external-key routing through global.db', () {
    test(
      'insert records the route so getByExternal finds the ticket',
      () async {
        await repo.insert(
          _ticket(
            id: 't-1',
            provider: TicketProvider.linear,
            externalKey: 'ENG-42',
          ),
        );

        expect(
          await global.workspaceRouteDao.resolve(
            WorkspaceRouteKind.ticketExternalKey,
            'linear:ENG-42',
          ),
          'ws-1',
        );
        expect(
          (await repo.getByExternal(TicketProvider.linear, 'ENG-42'))!.id,
          't-1',
        );
      },
    );

    test(
      'getByExternal reaches into whichever workspace owns the mirror',
      () async {
        await repo.upsertMirror(
          _ticket(
            id: 't-2',
            workspaceId: 'ws-2',
            provider: TicketProvider.linear,
            externalKey: 'ENG-7',
            title: 'Lives in ws-2',
          ),
        );

        final loaded = await repo.getByExternal(TicketProvider.linear, 'ENG-7');
        expect(loaded, isNotNull);
        expect(loaded!.workspaceId, 'ws-2');
        // ...and it is genuinely only in ws-2's file.
        expect(await repo.getById('ws-1', 't-2'), isNull);
        expect(await repo.getById('ws-2', 't-2'), isNotNull);
      },
    );

    test('an external key attached on update is routed too', () async {
      await repo.insert(_ticket(id: 't-1', title: 'local only'));
      expect(await repo.getByExternal(TicketProvider.linear, 'ENG-9'), isNull);

      await repo.update(
        _ticket(
          id: 't-1',
          title: 'pushed to linear',
          provider: TicketProvider.linear,
          externalKey: 'ENG-9',
          version: 1,
        ),
      );

      expect(
        (await repo.getByExternal(TicketProvider.linear, 'ENG-9'))!.id,
        't-1',
      );
    });

    test(
      'delete drops the route so no webhook resolves to a dead ticket',
      () async {
        await repo.insert(
          _ticket(
            id: 't-1',
            provider: TicketProvider.linear,
            externalKey: 'ENG-1',
          ),
        );

        await repo.delete('t-1', workspaceId: 'ws-1');

        expect(
          await global.workspaceRouteDao.resolve(
            WorkspaceRouteKind.ticketExternalKey,
            'linear:ENG-1',
          ),
          isNull,
        );
        expect(
          await repo.getByExternal(TicketProvider.linear, 'ENG-1'),
          isNull,
        );
      },
    );
  });
}
